class MaintenanceLog {
  final int id;
  final int diagnosisId;
  final String actionTaken;
  final String? partsReplaced;
  final double cost;
  final String? technician;
  final DateTime createdAt;

  MaintenanceLog({
    required this.id,
    required this.diagnosisId,
    required this.actionTaken,
    this.partsReplaced,
    required this.cost,
    this.technician,
    required this.createdAt,
  });

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    return MaintenanceLog(
      id: json['id'] as int,
      diagnosisId: json['diagnosis_id'] as int,
      actionTaken: json['action_taken'] as String,
      partsReplaced: json['parts_replaced'] as String?,
      cost: (json['cost'] as num).toDouble(),
      technician: json['technician'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnosis_id': diagnosisId,
      'action_taken': actionTaken,
      'parts_replaced': partsReplaced,
      'cost': cost,
      'technician': technician,
    };
  }
}
