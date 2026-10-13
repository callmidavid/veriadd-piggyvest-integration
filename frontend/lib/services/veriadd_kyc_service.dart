import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/veriadd_kyc_request.dart';

class VeriaddKycService {
  static const String defaultBackendUrl = 'http://localhost:8080';

  static HttpClientFactory? _httpClientFactory;

  static void setHttpClientFactory(HttpClientFactory factory) {
    _httpClientFactory = factory;
  }

  static String get backendUrl {
    const fromEnvironment = String.fromEnvironment(
      'VERIADD_BACKEND_URL',
      defaultValue: defaultBackendUrl,
    );
    return fromEnvironment;
  }

  Future<VeriaddKycResult> verifyAddress(VeriaddKycRequest request) async {
    final client = _httpClientFactory?.call() ?? http.Client();
    try {
      final response = await client.post(
        Uri.parse('$backendUrl/kyc/verify-address'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 20));

      final body = response.body.isEmpty ? '{}' : response.body;
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return VeriaddKycResult.fromJson(decoded);
      }

      final message = decoded['error'] ?? 'Address verification failed';
      throw Exception(message);
    } catch (error) {
      rethrow;
    } finally {
      if (_httpClientFactory == null) {
        client.close();
      }
    }
  }
}

typedef HttpClientFactory = http.Client Function();
