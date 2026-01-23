import 'package:kitchenowl/models/model.dart';

class LoyaltyCard extends Model {
  final int? id;
  final String name;
  final String barcodeType;
  final String barcodeData;
  final String? description;
  final String? image;
  final String? imageHash;
  final int? color;

  const LoyaltyCard({
    this.id,
    this.name = '',
    this.barcodeType = 'CODE128',
    this.barcodeData = '',
    this.description,
    this.image,
    this.imageHash,
    this.color,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> map) {
    return LoyaltyCard(
      id: map['id'],
      name: map['name'] ?? '',
      barcodeType: map['barcode_type'] ?? 'CODE128',
      barcodeData: map['barcode_data'] ?? '',
      description: map['description'],
      image: map['photo'],
      imageHash: map['photo_hash'],
      color: map['color'],
    );
  }

  LoyaltyCard copyWith({
    String? name,
    String? barcodeType,
    String? barcodeData,
    String? description,
    String? image,
    int? color,
  }) =>
      LoyaltyCard(
        id: id,
        name: name ?? this.name,
        barcodeType: barcodeType ?? this.barcodeType,
        barcodeData: barcodeData ?? this.barcodeData,
        description: description ?? this.description,
        image: image ?? this.image,
        imageHash: imageHash,
        color: color ?? this.color,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        barcodeType,
        barcodeData,
        description,
        image,
        imageHash,
        color,
      ];

  @override
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "barcode_type": barcodeType,
      "barcode_data": barcodeData,
      if (description != null) "description": description,
      if (image != null) "photo": image,
      if (color != null) "color": color,
    };
  }

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
      if (imageHash != null) "photo_hash": imageHash,
    });
}

