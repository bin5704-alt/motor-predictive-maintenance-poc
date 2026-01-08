class Equipment {
  final int id;
  final String name;
  final String status; // 'Operational', 'Maintenance', 'Critical', 'Stopped'
  final double efficiency;
  final DateTime? lastUpdated;

  Equipment({
    required this.id,
    required this.name,
    required this.status,
    required this.efficiency,
    this.lastUpdated,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as int,
      name: json['name'] as String,
      status: json['status'] as String,
      efficiency: (json['efficiency'] as num).toDouble(),
      lastUpdated: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
