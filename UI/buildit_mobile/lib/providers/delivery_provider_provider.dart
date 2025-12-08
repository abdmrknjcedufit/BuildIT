import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/delivery_provider_model.dart';

class DeliveryProviderProvider extends BaseProvider<DeliveryProvider> {
  DeliveryProviderProvider() : super("DeliveryProvider");

  @override
  DeliveryProvider fromJson(data) {
    return DeliveryProvider.fromJson(data);
  }
}

