// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => AuditLog(
  id: (json['id'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  userId: (json['userId'] as num?)?.toInt(),
  username: json['username'] as String?,
  action: json['action'] as String,
  entityId: json['entityId'] as String?,
  requestData: json['requestData'] as String?,
  responseStatus: json['responseStatus'] as String,
  message: json['message'] as String?,
);

Map<String, dynamic> _$AuditLogToJson(AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'timestamp': instance.timestamp.toIso8601String(),
  'userId': instance.userId,
  'username': instance.username,
  'action': instance.action,
  'entityId': instance.entityId,
  'requestData': instance.requestData,
  'responseStatus': instance.responseStatus,
  'message': instance.message,
};
