import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phone;
  final String? address;
  final int? cityId;
  final String? postalCode;
  final DateTime birthDate;
  final bool isActive;
  final DateTime createdAt;
  final List<String> roles;
  final String? userType;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phone,
    this.address,
    this.cityId,
    this.postalCode,
    required this.birthDate,
    required this.isActive,
    required this.createdAt,
    required this.roles,
    this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

