// Barcode scanner helper for web platform
// Uses Html5-QRCode library to decode barcodes from images

// Map Html5QrcodeScanner format to our string format
function formatToString(format) {
  if (!format) return 'CODE128';
  
  const formatMap = {
    'QR_CODE': 'QR',
    'AZTEC': 'AZTEC',
    'CODABAR': 'CODABAR',
    'CODE_39': 'CODE39',
    'CODE_93': 'CODE93',
    'CODE_128': 'CODE128',
    'DATA_MATRIX': 'DATAMATRIX',
    'MAXICODE': 'CODE128',
    'ITF': 'ITF',
    'EAN_13': 'EAN13',
    'EAN_8': 'EAN8',
    'PDF_417': 'PDF417',
    'RSS_14': 'CODE128',
    'RSS_EXPANDED': 'CODE128',
    'UPC_A': 'UPCA',
    'UPC_E': 'UPCE',
    'UPC_EAN_EXTENSION': 'EAN13',
  };
  
  return formatMap[format] || 'CODE128';
}

// Decode barcode from base64 image data
// Returns: { data: string, type: string } or null if not found
async function decodeBarcode(base64Data) {
  console.log('decodeBarcode called, data length:', base64Data ? base64Data.length : 0);
  
  // Check if Html5Qrcode is available
  if (typeof Html5Qrcode === 'undefined') {
    console.error('Html5Qrcode library not found');
    return null;
  }

  try {
    // Add data URL prefix if not present
    let imageDataUrl;
    if (base64Data.startsWith('data:')) {
      imageDataUrl = base64Data;
    } else {
      imageDataUrl = 'data:image/png;base64,' + base64Data;
    }
    
    console.log('Attempting to decode barcode from image...');
    
    // Convert data URL to File object
    const response = await fetch(imageDataUrl);
    const blob = await response.blob();
    const file = new File([blob], 'barcode.png', { type: 'image/png' });
    
    console.log('File created:', file.size, 'bytes');
    
    // Configure to scan ALL barcode formats
    const config = {
      verbose: false,
      formatsToSupport: [
        Html5QrcodeSupportedFormats.QR_CODE,
        Html5QrcodeSupportedFormats.AZTEC,
        Html5QrcodeSupportedFormats.CODABAR,
        Html5QrcodeSupportedFormats.CODE_39,
        Html5QrcodeSupportedFormats.CODE_93,
        Html5QrcodeSupportedFormats.CODE_128,
        Html5QrcodeSupportedFormats.DATA_MATRIX,
        Html5QrcodeSupportedFormats.ITF,
        Html5QrcodeSupportedFormats.EAN_13,
        Html5QrcodeSupportedFormats.EAN_8,
        Html5QrcodeSupportedFormats.PDF_417,
        Html5QrcodeSupportedFormats.UPC_A,
        Html5QrcodeSupportedFormats.UPC_E,
      ]
    };
    
    // Use Html5Qrcode to scan from file
    // The temp-reader div is defined in index.html
    const html5QrCode = new Html5Qrcode("temp-reader", config);
    
    // scanFileV2 with showImage=true to help with detection
    const result = await html5QrCode.scanFileV2(file, true);
    
    console.log('Barcode found:', result.decodedText, 'Format:', result.result.format.formatName);
    
    return {
      data: result.decodedText,
      type: formatToString(result.result.format.formatName)
    };
  } catch (error) {
    // Handle "No barcode or QR code detected" error
    const errorStr = error ? error.toString() : '';
    if (errorStr.includes('No barcode') || errorStr.includes('No QR code') || 
        errorStr.includes('No MultiFormat') || errorStr.includes('NotFoundException')) {
      console.log('No barcode found in image');
      return null;
    }
    console.error('Barcode decode error:', error);
    return null;
  }
}

// Expose functions to Dart via window object
window.decodeBarcode = decodeBarcode;

// Log when script is loaded
console.log('Barcode scanner script loaded (using Html5Qrcode with all formats)');
