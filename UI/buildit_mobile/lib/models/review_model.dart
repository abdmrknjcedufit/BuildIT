class Review {
  final int id;
  final int reviewerId;
  final String targetType;
  final int targetId;
  final int rating;
  final String? comment;
  final int? transactionId;
  final bool isApproved;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerId,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.comment,
    this.transactionId,
    required this.isApproved,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      reviewerId: json['reviewerId'] as int,
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      transactionId: json['transactionId'] as int?,
      isApproved: json['isApproved'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
