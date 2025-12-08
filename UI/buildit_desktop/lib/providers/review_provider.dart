import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/review_model.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Review");

  @override
  Review fromJson(data) {
    return Review.fromJson(data);
  }
}
