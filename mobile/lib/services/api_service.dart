import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class ApiService {
  /// Sends raw text or Base64 image data to the serverless parser backend
  Future<Map<String, dynamic>> parseReceipt({
    required String data,
    required bool isImage,
    required String baseUrl,
  }) async {
    final sanitizedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$sanitizedBaseUrl/api/parse-receipt');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'data': data,
          'isImage': isImage,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return {
            'success': true,
            'provider': decoded['provider'] ?? 'unknown',
            'data': decoded['data'],
          };
        } else {
          return {
            'success': false,
            'error': decoded['error'] ?? 'Parsing returned unsuccessful response.',
          };
        }
      } else {
        // Parse error message if available
        try {
          final decoded = jsonDecode(response.body);
          return {
            'success': false,
            'error': decoded['error'] ?? 'Server error (${response.statusCode})',
            'details': decoded['details'],
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Server error: Status Code ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network connection failed: ${e.toString()}',
      };
    }
  }

  /// Checks the backend API health status
  Future<Map<String, dynamic>> checkHealth(String baseUrl) async {
    final sanitizedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$sanitizedBaseUrl/api/health');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          'success': true,
          'status': decoded['status'],
          'activeProvider': decoded['activeProvider'],
          'configuredProviders': decoded['configuredProviders'],
        };
      }
      return {'success': false, 'error': 'Status code ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
