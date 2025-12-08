// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  cityId: json['cityId'] as int?,
  postalCode: json['postalCode'] as String?,
  birthDate: DateTime.parse(json['birthDate'] as String),
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  userType: json['userType'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'username': instance.username,
  'email': instance.email,
  'phone': instance.phone,
  'address': instance.address,
  'cityId': instance.cityId,
  'postalCode': instance.postalCode,
  'birthDate': instance.birthDate.toIso8601String(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'roles': instance.roles,
  'userType': instance.userType,
};
