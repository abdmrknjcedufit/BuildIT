import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/cart_model.dart';

class CartProvider extends BaseProvider<Cart> {
  CartProvider() : super("Cart");

  @override
  Cart fromJson(data) {
    return Cart.fromJson(data);
  }
}

