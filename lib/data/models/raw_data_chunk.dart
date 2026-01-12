class RawDataChunk {
  final int? id;
  final String? userId; // Nullable for local usage, but required for DB
  final DateTime startTime;
  final int samplingRate;
  final List<double> samples;

  RawDataChunk({
    this.id,
    this.userId,
    required this.startTime,
    required this.samplingRate,
    required this.samples,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'sampling_rate': samplingRate,
      'samples': samples,
    };
  }

  factory RawDataChunk.fromMap(Map<String, dynamic> map) {
    return RawDataChunk(
      id: map['id']?.toInt(),
      userId: map['user_id'],
      startTime: DateTime.parse(map['start_time']),
      samplingRate: map['sampling_rate']?.toInt() ?? 0,
      samples: List<double>.from(map['samples'] ?? []),
    );
  }
}
