import 'package:buildit_mobile/models/city_model.dart';
import 'package:buildit_mobile/providers/base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("City");

  @override
  City fromJson(data) {
    return City.fromJson(data);
  }
}

