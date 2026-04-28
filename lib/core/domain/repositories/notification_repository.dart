abstract class NotificationRepository {
  /// Menampilkan notifikasi lokal ke layar pengguna (Heads-Up).
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  });
}
