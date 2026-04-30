import 'package:news_app/core/error/exceptions.dart';

/// Mengkonversi raw Exception menjadi pesan yang ramah untuk ditampilkan ke pengguna.
///
/// MASALAH YANG DISELESAIKAN:
/// Tanpa helper ini, setiap Cubit/BLoC yang memiliki blok `catch (e)`
/// akan menulis logika if-else yang sama berulang kali (DRY violation).
///
/// CARA PAKAI:
/// ```dart
/// } catch (e) {
///   emit(state.copyWith(
///     status: MyStatus.failure,
///     errorMessage: ExceptionMapper.toMessage(e),
///   ));
/// }
/// ```
///
/// CATATAN ARSITEKTUR:
/// Helper ini HANYA dipakai di Presentation Layer (Cubit/BLoC) untuk kasus
/// di mana exception TIDAK melewati Repository (misal: upload file langsung
/// dari Cubit via ApiClient). Untuk aliran normal melalui Repository,
/// gunakan `Left(Failure).message` dari pattern Either.
class ExceptionMapper {
  ExceptionMapper._(); // Prevent instantiation

  /// Memetakan exception ke pesan yang bisa langsung ditampilkan ke user.
  static String toMessage(Object e) {
    if (e is NetworkException) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    } else if (e is ServerException) {
      // Jika server mengembalikan 500+, itu pasti error internal, jangan tampilkan pesan raw
      if (e.statusCode != null && e.statusCode! >= 500) {
        return 'Terjadi kesalahan pada server. Tim kami sedang memperbaikinya.';
      }

      // Filter pesan teknis yang bocor dari backend (seperti SQL, panic, dll)
      final msg = e.message.toLowerCase();
      if (msg.contains('sql:') || 
          msg.contains('panic:') || 
          msg.contains('dial tcp') || 
          msg.contains('connection refused') ||
          msg.contains('null pointer')) {
        return 'Sistem sedang mengalami gangguan. Silakan coba beberapa saat lagi.';
      }

      // Pesan aman dari server (misal: "Email sudah terdaftar", "Password salah")
      return e.message;
    } else if (e is UnauthorizedException) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else if (e is CacheException) {
      return 'Gagal membaca data tersimpan. Coba restart aplikasi.';
    } else if (e is ParsingException) {
      return 'Terjadi kesalahan memproses data dari server.';
    } else {
      // Fallback untuk exception tak terduga (jangan tampilkan e.toString()!)
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
