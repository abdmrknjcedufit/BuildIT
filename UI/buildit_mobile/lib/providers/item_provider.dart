import 'package:buildit_mobile/models/item_model.dart';
import 'package:buildit_mobile/providers/base_provider.dart';

class ItemProvider extends BaseProvider<Item> {
  ItemProvider() : super("Item");

  @override
  Item fromJson(data) {
    return Item.fromJson(data);
  }
}

