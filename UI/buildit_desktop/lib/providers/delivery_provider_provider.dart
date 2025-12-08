import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/delivery_provider_model.dart';

class DeliveryProviderProvider extends BaseProvider<DeliveryProvider> {
  DeliveryProviderProvider() : super("DeliveryProvider");

  @override
  DeliveryProvider fromJson(data) {
    return DeliveryProvider.fromJson(data);
  }
}

