import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Setup konfigurasi Android. 
    // Kita panggil @mipmap/ic_launcher (icon default bawaan aplikasi)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Setup konfigurasi iOS (Darwin).
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3. Gabungkan keduanya
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 4. Inisialisasi Plugin Utama
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Disini kita bisa mengatur aksi jika notifikasi di-tap.
        // Contoh: print payload atau navigasi ke halaman spesifik.
        print('Notifikasi diklik! Payload: ${response.payload}');
      },
    );

    // 5. (Khusus Android 13+) Kita harus secara manual meminta izin POST_NOTIFICATIONS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Bikin KTP (Notification Channel) untuk Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'news_app_general', // ID Channel
      'Notifikasi Umum',  // Nama Channel (muncul di Settings OS)
      channelDescription: 'Channel ini digunakan untuk notifikasi profil dan info umum.',
      importance: Importance.max, // Biar notifikasinya pop-up dari atas layar
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    // TEMBAK NOTIFIKASI!
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
