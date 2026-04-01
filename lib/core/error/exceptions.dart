class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({this.message = 'Unauthorized'});
}
