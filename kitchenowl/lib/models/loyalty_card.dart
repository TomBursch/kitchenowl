import 'package:kitchenowl/models/model.dart';

class LoyaltyCard extends Model {
  final int? id;
  final String name;
  final String? barcodeType;
  final String? barcodeData;
  final String? description;
  final int? color;

  const LoyaltyCard({
    this.id,
    this.name = '',
    this.barcodeType,
    this.barcodeData,
    this.description,
    this.color,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> map) {
    return LoyaltyCard(
      id: map['id'],
      name: map['name'] ?? '',
      barcodeType: map['barcode_type'],
      barcodeData: map['barcode_data'],
      description: map['description'],
      color: map['color'],
    );
  }

  LoyaltyCard copyWith({
    String? name,
    String? barcodeType,
    String? barcodeData,
    String? description,
    int? color,
  }) =>
      LoyaltyCard(
        id: id,
        name: name ?? this.name,
        barcodeType: barcodeType ?? this.barcodeType,
        barcodeData: barcodeData ?? this.barcodeData,
        description: description ?? this.description,
        color: color ?? this.color,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        barcodeType,
        barcodeData,
        description,
        color,
      ];

  @override
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      if (barcodeType != null) "barcode_type": barcodeType,
      if (barcodeData != null) "barcode_data": barcodeData,
      if (description != null) "description": description,
      if (color != null) "color": color,
    };
  }

  @override
  Map<String, dynamic> toJsonWithId() => toJson()
    ..addAll({
      "id": id,
    });
}

