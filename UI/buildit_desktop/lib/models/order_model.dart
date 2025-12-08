import 'package:buildit_desktop/models/user_model.dart';
import 'package:buildit_desktop/models/transaction_model.dart';
import 'package:buildit_desktop/models/delivery_provider_model.dart';

class Order {
  final int id;
  final int userId;
  final String orderNumber;
  final String status;
  final String orderType;
  final double totalAmount;
  final double? discountAmount;
  final double? taxAmount;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final int? transactionId;
  final String? shippingAddress;
  final String? billingAddress;
  final DateTime? expectedDeliveryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isInvoiceGenerated;
  final String priority;
  final int? deliveryProviderId;
  final String? deliveryType;
  final User? user;
  final Transaction? transaction;
  final DeliveryProvider? deliveryProvider;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.orderType,
    required this.totalAmount,
    this.discountAmount,
    this.taxAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionId,
    this.shippingAddress,
    this.billingAddress,
    this.expectedDeliveryDate,
    required this.createdAt,
    this.updatedAt,
    required this.isInvoiceGenerated,
    required this.priority,
    this.deliveryProviderId,
    this.deliveryType,
    this.user,
    this.transaction,
    this.deliveryProvider,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      userId: json['userId'] as int,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      orderType: json['orderType'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discountAmount: json['discountAmount'] != null ? (json['discountAmount'] as num).toDouble() : null,
      taxAmount: json['taxAmount'] != null ? (json['taxAmount'] as num).toDouble() : null,
      finalAmount: (json['finalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      transactionId: json['transactionId'] as int?,
      shippingAddress: json['shippingAddress'] as String?,
      billingAddress: json['billingAddress'] as String?,
      expectedDeliveryDate: json['expectedDeliveryDate'] != null ? DateTime.parse(json['expectedDeliveryDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      isInvoiceGenerated: json['isInvoiceGenerated'] as bool,
      priority: json['priority'] as String,
      deliveryProviderId: json['deliveryProviderId'] as int?,
      deliveryType: json['deliveryType'] as String?,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      transaction: json['transaction'] != null ? Transaction.fromJson(json['transaction'] as Map<String, dynamic>) : null,
      deliveryProvider: json['deliveryProvider'] != null ? DeliveryProvider.fromJson(json['deliveryProvider'] as Map<String, dynamic>) : null,
    );
  }
}

