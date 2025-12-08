import 'package:json_annotation/json_annotation.dart';

part 'audit_log_model.g.dart';

@JsonSerializable()
class AuditLog {
  final int id;
  final DateTime timestamp;
  final int? userId;
  final String? username;
  final String action;
  final String? entityId;
  final String? requestData;
  final String responseStatus;
  final String? message;

  AuditLog({
    required this.id,
    required this.timestamp,
    this.userId,
    this.username,
    required this.action,
    this.entityId,
    this.requestData,
    required this.responseStatus,
    this.message,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => _$AuditLogFromJson(json);

  Map<String, dynamic> toJson() => _$AuditLogToJson(this);
}

