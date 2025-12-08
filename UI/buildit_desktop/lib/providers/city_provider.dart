import 'package:buildit_desktop/models/city_model.dart';
import 'package:buildit_desktop/providers/base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("City");

  @override
  City fromJson(data) {
    return City.fromJson(data);
  }
}

