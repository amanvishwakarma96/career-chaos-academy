import '../models/production_security_model.dart';
import 'api_client.dart';

class ProductionSecurityService {
  ProductionSecurityService._();

  static final ProductionSecurityService instance = ProductionSecurityService._();

  Future<ProductionSecurityPolicyModel?> loadPolicy() async {
    if (!ApiClient.instance.isEnabled) return null;
    final json = await ApiClient.instance.getMap('/api/security/policy');
    return ProductionSecurityPolicyModel.fromJson(json);
  }

  Future<ProductionSecurityStatusModel?> loadAdminStatus() async {
    if (!ApiClient.instance.isEnabled) return null;
    final json = await ApiClient.instance.getMap('/api/admin/security/status');
    return ProductionSecurityStatusModel.fromJson(json);
  }

  Future<Map<String, dynamic>?> reportCrashPrototype({
    required Object error,
    required StackTrace stackTrace,
    String screen = 'unknown',
  }) async {
    if (!ApiClient.instance.isEnabled) return null;
    return ApiClient.instance.postMap('/api/errors/report', <String, dynamic>{
      'source': 'flutter_app',
      'severity': 'error',
      'message': error.toString(),
      'screen': screen,
      'stack': stackTrace.toString(),
      'metadata': <String, dynamic>{
        'surface': 'production_security_service',
      },
    });
  }
}
