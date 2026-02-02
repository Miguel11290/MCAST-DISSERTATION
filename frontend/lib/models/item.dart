class Item {
  final int id;
  final String name;
  final String? hazardClass;
  final String? unit;
  final double? maxSafeQuantity;

  Item({
    required this.id,
    required this.name,
    this.hazardClass,
    this.unit,
    this.maxSafeQuantity,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      hazardClass: json['hazard_class'],
      unit: json['unit'],
      maxSafeQuantity:
          (json["max_safe_quantity"] == null)
              ? null
              : (json["max_safe_quantity"] as num).toDouble(),
    );
  }
}
