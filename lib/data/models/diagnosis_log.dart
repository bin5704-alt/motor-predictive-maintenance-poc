class DiagnosisLog {
  final int id;
  final String userId;
  final double score;
  final String status;
  final Map<String, dynamic>? metrics;
  final Map<String, dynamic>? prescription;
  final int? rawDataId;
  final DateTime createdAt;

  DiagnosisLog({
    required this.id,
    required this.userId,
    required this.score,
    required this.status,
    this.metrics,
    this.prescription,
    this.rawDataId,
    required this.createdAt,
  });

  factory DiagnosisLog.fromJson(Map<String, dynamic> json) {
    return DiagnosisLog(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      score: (json['score'] as num).toDouble(),
      status: json['status'] as String,
      metrics: json['metrics'] as Map<String, dynamic>?,
      prescription: json['prescription'] as Map<String, dynamic>?,
      rawDataId: json['raw_data_id'] as int?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'score': score,
      'status': status,
      'metrics': metrics,
      'prescription': prescription,
      'raw_data_id': rawDataId,
      // 'created_at' is usually handled by DB default
    };
  }
}
