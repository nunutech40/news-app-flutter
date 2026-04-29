import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:news_app/core/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Disini kita bisa mengatur aksi jika notifikasi di-tap.
        print('Notifikasi diklik! Payload: ${response.payload}');
      },
    );

    // Khusus Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'news_app_brutal', 
      'Notifikasi Darurat',  
      channelDescription: 'Channel ini tidak bisa diabaikan.',
      importance: Importance.max,
      priority: Priority.max, // MAKSIMAL
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 2000, 500, 3000]), // GETARAN POLA
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0), // KEDIP MERAH
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: const BigTextStyleInformation(
        'INI ADALAH TEKS PANJANG YANG TIDAK BISA DITUTUPI. BACA SEKARANG JUGA ATAU HP INI AKAN MELEDAK! 🔥🔥🔥',
        htmlFormatBigText: true,
        contentTitle: '<b>URGENT ALERT!</b>',
        htmlFormatContentTitle: true,
        summaryText: 'Darurat Profil',
      ),
      fullScreenIntent: true, // MAKSA BUKA LAYAR
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
