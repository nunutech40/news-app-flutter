extension DateTimeExtension on DateTime? {
  /// Converts a DateTime to a relative time string (e.g., "5m ago", "1h ago", "2d ago")
  String get timeAgo {
    if (this == null) return '';
    final diff = DateTime.now().difference(this!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
