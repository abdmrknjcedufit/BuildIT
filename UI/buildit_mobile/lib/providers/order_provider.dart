import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/order_model.dart';

class OrderProvider extends BaseProvider<Order> {
  OrderProvider() : super("Order");

  @override
  Order fromJson(data) {
    return Order.fromJson(data as Map<String, dynamic>);
  }
}

