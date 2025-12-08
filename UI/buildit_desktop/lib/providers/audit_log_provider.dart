import 'package:buildit_desktop/models/audit_log_model.dart';
import 'package:buildit_desktop/providers/base_provider.dart';

class AuditLogProvider extends BaseProvider<AuditLog> {
  AuditLogProvider() : super("AuditLog");

  @override
  AuditLog fromJson(data) {
    return AuditLog.fromJson(data);
  }
}

