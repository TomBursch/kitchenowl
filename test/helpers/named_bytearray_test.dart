import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/helpers/named_bytearray.dart';

void main() {
  test("Create NamedByteArray without name", () {
    expect(() => NamedByteArray('', Uint8List(5)), throwsAssertionError);
  });

  test("Create NamedByteArray without data", () {
    expect(() => NamedByteArray('foo', Uint8List(0)), throwsAssertionError);
  });

  test("Create normal NamedByteArray", () {
    var array = NamedByteArray('foo', Uint8List.fromList([1, 2, 3]));
    expect(array.filename, equals('foo'));
    expect(array.bytes, equals(Uint8List.fromList([1, 2, 3])));
    expect(array.isEmpty, isFalse);
    expect(array.isNotEmpty, isTrue);
  });

  test("Use empty NamedByteArray", () {
    var array = NamedByteArray.empty;
    expect(array.isEmpty, isTrue);
    expect(array.isNotEmpty, isFalse);
  });
}
