import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/transaction_model.dart';

class TransactionProvider extends BaseProvider<Transaction> {
  TransactionProvider() : super("Transaction");

  @override
  Transaction fromJson(data) {
    return Transaction.fromJson(data);
  }
}

