import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

// ============================================================
// IMAGE PROCESSOR HELPER
// Lapisan: Core / Utility
//
// Tanggung Jawab: Satu-satunya kelas yang boleh tahu cara
// memanipulasi pixel gambar (decode, crop, compress).
//
// Kenapa ada di core/utils dan BUKAN di UI?
// - UI hanya boleh "memerintah" dan "menerima hasil".
// - Proses I/O dan CPU yang berat ini wajib diisolasi agar:
//   1. Bisa dipakai ulang (reusable) oleh fitur apapun.
//   2. Mudah di-test secara unit (tidak ada dependency ke Widget).
//   3. Sesuai prinsip SRP (Single Responsibility Principle).
// ============================================================

/// Data Transfer Object (DTO) untuk membawa parameter ke dalam Isolate.
/// Kita butuh ini karena compute() hanya bisa menerima SATU parameter.
/// Daripada bikin parameter tunggal yang ambigu (misal: hanya String path),
/// kita bungkus semua konfigurasi ke dalam satu objek ini.
class _ImageProcessParams {
  final String path;
  final int targetSize; // Ukuran sisi dari hasil crop persegi (px)
  final int quality;   // Kualitas JPEG output (1-100)

  const _ImageProcessParams({
    required this.path,
    required this.targetSize,
    required this.quality,
  });
}

// ============================================================
// FUNGSI TOP-LEVEL (DI LUAR CLASS) - WAJIB untuk compute()!
//
// Kenapa harus Top-Level dan bukan method di dalam class?
// Karena compute() akan mengirim fungsi ini ke Worker Isolate
// yang memiliki memori terpisah. Isolate hanya bisa menjalankan
// fungsi yang tidak terikat ke instance class manapun (tidak
// ada referensi ke 'this'). Oleh karena itu fungsi ini HARUS
// berada di level paling atas (global/static).
// ============================================================
Future<String?> _processImageInIsolate(_ImageProcessParams params) async {
  try {
    // Langkah 1: Baca semua byte mentah dari file asli di disk.
    // File asli bisa berukuran 10-30 MB untuk foto dari kamera modern.
    final Uint8List imageBytes = await File(params.path).readAsBytes();

    // Langkah 2: Decode byte mentah menjadi objek Image yang bisa diedit.
    // Ini adalah operasi paling berat: mengurai format JPEG/PNG/HEIC
    // menjadi representasi pixel-per-pixel di memori (RAM).
    final img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) return null;

    // Langkah 3: Crop dan resize sekaligus menjadi persegi (square).
    // Algoritma mengambil sisi terpendek sebagai patokan,
    // lalu memotong sisi yang lebih panjang dari tengah.
    final img.Image cropped = img.copyResizeCropSquare(
      decoded,
      size: params.targetSize,
    );

    // Langkah 4: Encode ulang menjadi JPEG dengan kualitas yang dikonfigurasi.
    // Ini mengurangi ukuran file secara drastis (dari ~20MB menjadi ~50-200KB)
    // sebelum dikirimkan ke server melalui Multipart HTTP request.
    final Uint8List outputBytes = img.encodeJpg(cropped, quality: params.quality);

    // Langkah 5: Tulis hasil ke file baru di disk dan kembalikan path-nya
    // ke Main Thread sebagai "hasil kerja" Isolate ini.
    final String outputPath = '${params.path}_processed.jpg';
    await File(outputPath).writeAsBytes(outputBytes);

    return outputPath;
  } catch (e) {
    // Jika terjadi error apapun di dalam Isolate, kembalikan null
    // agar caller (ProfileCubit) bisa mengaktifkan fallback logic.
    debugPrint('[ImageProcessor] Isolate error: $e');
    return null;
  }
}

/// Helper class yang menjadi satu-satunya pintu masuk
/// untuk semua operasi manipulasi gambar di seluruh aplikasi.
class ImageProcessorHelper {
  // Private constructor: mencegah class ini di-instantiate.
  // Semua method bersifat static, tidak perlu membuat objek.
  ImageProcessorHelper._();

  /// Mengompresi dan memotong gambar menjadi persegi menggunakan Worker Isolate.
  ///
  /// [originalPath]: Path file gambar asli dari ImagePicker.
  /// [targetSize]: Ukuran sisi output dalam pixel. Default: 500px.
  /// [quality]: Kualitas kompresi JPEG (1-100). Default: 80.
  ///
  /// Returns: Path file hasil kompresi, atau null jika gagal.
  /// Jika null, caller wajib mengimplementasikan fallback (pakai file asli).
  static Future<String?> compressAndCropSquare({
    required String originalPath,
    int targetSize = 500,
    int quality = 80,
  }) {
    // Bungkus semua parameter ke dalam DTO sebelum dikirim ke Isolate.
    final params = _ImageProcessParams(
      path: originalPath,
      targetSize: targetSize,
      quality: quality,
    );

    // compute() adalah cara termudah Flutter untuk melempar fungsi
    // ke Worker Isolate yang memanfaatkan Core CPU yang berbeda,
    // sehingga Main Thread (UI) tidak pernah tertunda/freeze.
    return compute(_processImageInIsolate, params);
  }
}
