class ServerException implements Exception {
  const ServerException(this.message);

  final String message;
}

class CacheException implements Exception {
  const CacheException(this.message);

  final String message;
}

class ReviewerException implements Exception {
  const ReviewerException(this.message);

  final String message;
}

