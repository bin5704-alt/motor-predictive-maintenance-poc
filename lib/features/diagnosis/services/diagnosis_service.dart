import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DiagnosisService {
  final String _baseUrl = 'http://localhost:8000';

  Future<bool> triggerDiagnosis(String userId) async {
    final url = Uri.parse('$_baseUrl/diagnose');
    try {
      debugPrint('Triggering diagnosis: POST $url');
      final response = await http.post(
        url,
        body: jsonEncode({'user_id': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        debugPrint('Diagnosis successful: ${response.body}');
        return true;
      } else {
        debugPrint(
          'Diagnosis failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error accessing diagnosis server: $e');
      return false;
    }
  }
}
