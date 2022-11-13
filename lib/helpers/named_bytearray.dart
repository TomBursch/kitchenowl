import 'dart:typed_data';

/// A byte array with a name.
/// Useful in situations where you want to represent some kind of file without relying on any filesystem.
class NamedByteArray {
  static final NamedByteArray empty = NamedByteArray._('', Uint8List(0));

  final String filename;
  final Uint8List bytes;

  NamedByteArray._(this.filename, this.bytes);

  NamedByteArray(this.filename, this.bytes) {
    assert(filename.isNotEmpty);
    assert(bytes.isNotEmpty);
  }

  bool get isEmpty => this == empty;

  bool get isNotEmpty => !isEmpty;
}
