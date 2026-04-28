import 'package:news_app/core/domain/repositories/notification_repository.dart';
import 'package:news_app/core/services/notification_service.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  @override
  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Delegasi tugas ke Service External (Infrastructure)
    await NotificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
