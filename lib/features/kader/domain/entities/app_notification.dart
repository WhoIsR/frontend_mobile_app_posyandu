class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.data = const {},
    this.isRead = false,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final Map<String, Object?> data;
  final bool isRead;
}
