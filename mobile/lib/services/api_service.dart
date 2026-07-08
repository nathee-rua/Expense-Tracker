import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Sends raw text or Base64 image data to the serverless parser backend
  Future<Map<String, dynamic>> parseReceipt({
    required String data,
    required bool isImage,
    required String baseUrl,
    String? provider,
    String? model,
    String? apiKey,
  }) async {
    final sanitizedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final url = Uri.parse('$sanitizedBaseUrl/api/parse-receipt');

    try {
      final bodyMap = {
        'data': data,
        'isImage': isImage,
      };

      if (provider != null) bodyMap['provider'] = provider;
      if (model != null) bodyMap['model'] = model;
      if (apiKey != null) bodyMap['apiKey'] = apiKey;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return {
            'success': true,
            'provider': decoded['provider'] ?? provider ?? 'unknown',
            'model': decoded['model'] ?? model ?? 'unknown',
            'data': decoded['data'],
          };
        } else {
          return {
            'success': false,
            'error': decoded['error'] ?? 'Parsing returned unsuccessful response.',
          };
        }
      } else {
        try {
          final decoded = jsonDecode(response.body);
          return {
            'success': false,
            'error': decoded['error'] ?? 'Server error (${response.statusCode})',
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

  /// Fetches the real-time models list for a specific provider from the backend
  Future<List<String>> fetchModels({
    required String provider,
    required String apiKey,
    required String baseUrl,
  }) async {
    final sanitizedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    // Construct query parameters
    final queryParams = <String, String>{
      'provider': provider,
    };
    if (apiKey.isNotEmpty) {
      queryParams['apiKey'] = apiKey;
    }

    final uri = Uri.parse('$sanitizedBaseUrl/api/models').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['models'] is List) {
          return List<String>.from(decoded['models']);
        }
      }
      return [];
    } catch (e) {
      print("Error fetching real-time models: $e");
      return [];
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
