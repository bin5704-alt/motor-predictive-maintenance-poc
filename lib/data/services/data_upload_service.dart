import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/raw_data_chunk.dart';

class DataUploadService {
  final SupabaseClient _supabase;
  final int uploadBatchSize; // Number of points before upload

  List<double> _buffer = [];
  DateTime? _bufferStartTime;

  DataUploadService(this._supabase, {this.uploadBatchSize = 2000});

  void addData(List<double> data, int samplingRate) {
    if (_buffer.isEmpty) {
      _bufferStartTime = DateTime.now();
    }

    _buffer.addAll(data);

    if (_buffer.length >= uploadBatchSize) {
      _flush(samplingRate);
    }
  }

  Future<void> _flush(int samplingRate) async {
    if (_buffer.isEmpty || _bufferStartTime == null) return;

    final user = _supabase.auth.currentUser;
    // Log warning if user is not logged in, but don't crash
    if (user == null) {
      debugPrint('Warning: No user logged in, skipping upload.');
      _buffer = [];
      _bufferStartTime = null;
      return;
    }

    final chunk = RawDataChunk(
      userId: user.id,
      startTime: _bufferStartTime!,
      samplingRate: samplingRate,
      samples: List.from(_buffer),
    );

    // Reset buffer immediately
    _buffer = [];
    _bufferStartTime = null;

    try {
      await _supabase.from('raw_sensor_data').insert(chunk.toMap());
    } catch (e) {
      // Silently fail for now, or log error.
      // In production, we'd use a persistent queue (Isar/Hive) for robustness.
      debugPrint('Failed to upload sensor data: $e');
    }
  }
}
