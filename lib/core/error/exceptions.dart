/// Exception ini dilempar ketika backend API mati, error internal (500),
/// atau memberikan validasi penolakan (400, 404) namun secara jaringan tetap sukses terkirim.
/// Exception ini akan selalu memiliki [message] dari server, dan opsional status kodenya.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});
}

/// Exception ini dilempar ketika operasi membaca/menulis memori lokal (HP) gagal.
/// Contoh kasus: SharedPreferences / SecureStorage terkunci oleh OS,
/// memory internal penuh, atau data yang dicari tidak ditemukan (null check throw).
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});
}

/// Exception ini secara spesifik dilempar BUKAN hanya jika HTTP merespon 401,
/// tetapi lebih ketika interceptor/lokal menyadari bahwa `accessToken` sudah tidak
/// bisa dipulihkan kembali (Refresh Token gagal), shingga BLoC harus bereaksi log-out.
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({this.message = 'Unauthorized'});
}

/// Exception ini dilempar murni akibat masalah INFRASTRUKTUR / perangkat keras (Hardware).
/// - Request Timeout (Server API tidak merespon walau ditunggu bermenit-menit)
/// - Connection Error (HP User mode pesawat, kuota habis, Wi-Fi tanpa akses, DNS down)
/// Di sinilah beda mutlak antara Server lemot vs Server meledak.
class NetworkException implements Exception {
  final String message;
  
  const NetworkException({this.message = 'Network connection failed'});
}

/// Exception pamungkas jika terjadi hal yang di luar wewenang kategori di atas,
/// misalnya gagal parsing JSON kotor dari endpoint karena miskomunikasi antar developer, 
/// atau tipe data berubah diam-diam.
class ParsingException implements Exception {
  final String message;

  const ParsingException({this.message = 'Failed to parse JSON data'});
}
