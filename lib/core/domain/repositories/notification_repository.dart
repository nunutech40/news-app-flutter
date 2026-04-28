abstract class NotificationRepository {
  /// Melakukan inisialisasi awal pengaturan plugin dan meminta izin OS
  Future<void> initialize();

  /// Menampilkan notifikasi lokal ke layar pengguna (Heads-Up).
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  });
}
