import 'package:news_app/core/constants/api_constants.dart';
import 'package:news_app/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.avatarUrl = '',
    super.bio = '',
    super.phone = '',
    super.preferences = '',
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Defensive casting: JSON numbers can come as int, double, or String
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: _resolveAvatarUrl(json['avatar_url']?.toString()),
      bio: json['bio']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      // sometimes preference comes as map, we encode it as string for simple state management
      preferences: json['preferences'] != null ? json['preferences'].toString() : '',
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone': phone,
      'preferences': preferences,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String _resolveAvatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final base = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
        : ApiConstants.baseUrl;
    final path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$base$path';
  }
}
