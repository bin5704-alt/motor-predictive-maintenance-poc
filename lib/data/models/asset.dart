class Asset {
  final int id;
  final String userId;
  final String name;
  final String type;
  final String? imageUrl;
  final Map<String, dynamic>? specifications;
  final DateTime createdAt;

  Asset({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.imageUrl,
    this.specifications,
    required this.createdAt,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      imageUrl: json['image_url'] as String?,
      specifications: json['specifications'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'type': type,
      'image_url': imageUrl,
      'specifications': specifications,
      // created_at is handled by DB defaults usually, but if needed:
      // 'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters for common specs
  int? get rpm => specifications?['rpm'] as int?;
  double? get voltage => (specifications?['voltage'] as num?)?.toDouble();
}
