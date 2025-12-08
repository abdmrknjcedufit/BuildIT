import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/review_model.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Review");

  @override
  Review fromJson(data) {
    return Review.fromJson(data);
  }
}
