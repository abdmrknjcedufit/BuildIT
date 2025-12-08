class DeliveryProvider {
  final int id;
  final String name;
  final String code;
  final double? price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DeliveryProvider({
    required this.id,
    required this.name,
    required this.code,
    this.price,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory DeliveryProvider.fromJson(Map<String, dynamic> json) {
    return DeliveryProvider(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

