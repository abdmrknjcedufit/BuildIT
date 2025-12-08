import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/cart_model.dart';

class CartProvider extends BaseProvider<Cart> {
  CartProvider() : super("Cart");

  @override
  Cart fromJson(data) {
    return Cart.fromJson(data);
  }
}

