import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:veriadd/veriadd.dart';

class KycRequest {
  final String postcode;
  final String state;
  final String bvn;
  final String phone;
  final int level;

  const KycRequest({
    required this.postcode,
    required this.state,
    required this.bvn,
    required this.phone,
    required this.level,
  });

  factory KycRequest.fromJson(Map<String, dynamic> json) {
    return KycRequest(
      postcode: (json['postcode'] ?? '').toString().trim(),
      state: (json['state'] ?? '').toString().trim(),
      bvn: (json['bvn'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      level: int.tryParse((json['level'] ?? '3').toString()) ?? 3,
    );
  }

  bool get hasRequiredFields =>
      postcode.isNotEmpty &&
      state.isNotEmpty &&
      bvn.isNotEmpty &&
      phone.isNotEmpty &&
      level >= 1 &&
      level <= 5;

  Map<String, dynamic> toJson() => {
        'postcode': postcode,
        'state': state,
        'bvn': bvn,
        'phone': phone,
        'level': level,
      };
}

class KycValidationResult {
  final bool isValid;
  final String? message;

  const KycValidationResult({required this.isValid, this.message});

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        if (message != null) 'message': message,
      };
}

KycValidationResult validateKycPayload(Map<String, dynamic> payload) {
  final request = KycRequest.fromJson(payload);

  if (request.postcode.isEmpty) {
    return const KycValidationResult(
      isValid: false,
      message: 'postcode is required',
    );
  }

  if (request.state.isEmpty) {
    return const KycValidationResult(
      isValid: false,
      message: 'state is required',
    );
  }

  if (request.bvn.length != 11 || !RegExp(r'^\d{11}$').hasMatch(request.bvn)) {
    return const KycValidationResult(
      isValid: false,
      message: 'bvn must be 11 digits',
    );
  }

  if (request.phone.isEmpty || !RegExp(r'^(\+?\d{8,15})$').hasMatch(request.phone)) {
    return const KycValidationResult(
      isValid: false,
      message: 'phone must contain 8 to 15 digits, optionally with a leading +',
    );
  }

  if (request.level < 1 || request.level > 5) {
    return const KycValidationResult(
      isValid: false,
      message: 'level must be between 1 and 5',
    );
  }

  return const KycValidationResult(isValid: true);
}

Future<Response> _verifyAddress(Request request) async {
  try {
    final body = await request.readAsString();
    Map<String, dynamic> payload = const {};

    if (body.trim().isNotEmpty) {
      payload = jsonDecode(body) is Map<String, dynamic>
          ? jsonDecode(body) as Map<String, dynamic>
          : Map<String, dynamic>.from(jsonDecode(body) as Map);
    }

    final validation = validateKycPayload(payload);
    if (!validation.isValid) {
      return Response(400, body: jsonEncode({'error': validation.message}));
    }

    final key = Platform.environment['VERIADD_KEY'];
    if (key == null || key.trim().isEmpty) {
      return Response(
        500,
        body: jsonEncode({
          'error': 'VERIADD_KEY is not configured on the server',
        }),
      );
    }

    final veriadd = VeriaddClient(apiKey: key);
    try {
      final result = await veriadd.verifyAddress(
        VeriaddVerifyInput(
          postcode: payload['postcode'] as String,
          state: payload['state'] as String,
          bvn: payload['bvn'] as String,
          phone: payload['phone'] as String,
          level: int.tryParse((payload['level'] ?? '3').toString()) ?? 3,
        ),
      );

      final responseBody = {
        'verified': result.status == 'verified',
        'status': result.status,
        'confidence': result.confidence,
        'auditId': result.auditId,
        'reasons': result.reasons,
        'postcodeCanonical': result.postcodeCanonical,
      };

      return Response.ok(
        jsonEncode(responseBody),
        headers: {'Content-Type': 'application/json'},
      );
    } on VeriaddError catch (error) {
      return Response(
        422,
        body: jsonEncode({
          'error': error.message,
          'code': error.code,
          'requestId': error.requestId,
        }),
      );
    } catch (error) {
      return Response(
        502,
        body: jsonEncode({
          'error': 'Upstream verification request failed',
          'detail': error.toString(),
        }),
      );
    } finally {
      veriadd.close();
    }
  } catch (error) {
    return Response(
      400,
      body: jsonEncode({
        'error': 'Request body must be valid JSON',
        'detail': error.toString(),
      }),
    );
  }
}

Handler _buildRouter() {
  final router = Router();

  router.post('/kyc/verify-address', _verifyAddress);
  router.options('/kyc/verify-address', (_) {
    return Response.ok(
      '',
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
  });

  router.get('/health', (_) {
    return Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return Pipeline().addMiddleware(
    logRequests(),
  ).addMiddleware(
    _corsMiddleware,
  ).addHandler(router);
}

Middleware get _corsMiddleware => (innerHandler) {
  return (request) async {
    final response = await innerHandler(request);
    return response.change(
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
  };
};

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final handler = _buildRouter();

  final server = await serve(handler, '0.0.0.0', port);
  print('Veriadd KYC backend running on http://${server.address.host}:${server.port}');
}
