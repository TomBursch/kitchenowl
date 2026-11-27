import 'dart:js_interop';

// The document's <base href>, not Uri.base: on the web Uri.base is the page
// URL, so opening a deep link (/household/1/planner) made the API base
// /household/1/planner/api and every request got index.html back.
@JS('document.baseURI')
external String get _documentBaseUri;

String getBaseUri() {
  return _documentBaseUri;
}
