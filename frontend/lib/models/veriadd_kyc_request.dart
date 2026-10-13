class VeriaddKycRequest {
  final String postcode;
  final String state;
  final String bvn;
  final String phone;
  final int level;

  const VeriaddKycRequest({
    required this.postcode,
    required this.state,
    required this.bvn,
    required this.phone,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        'postcode': postcode,
        'state': state,
        'bvn': bvn,
        'phone': phone,
        'level': level,
      };
}

class VeriaddKycResult {
  final bool verified;
  final String status;
  final int confidence;
  final String auditId;
  final List<String> reasons;

  const VeriaddKycResult({
    required this.verified,
    required this.status,
    required this.confidence,
    required this.auditId,
    required this.reasons,
  });

  factory VeriaddKycResult.fromJson(Map<String, dynamic> json) {
    return VeriaddKycResult(
      verified: json['verified'] as bool? ?? false,
      status: json['status'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      auditId: json['auditId'] as String? ?? '',
      reasons: (json['reasons'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
