class NotificationModel {
  final String id;
  final String title;
  final String priority;
  final String timeLabel;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.timeLabel,
    this.isRead = false,
  });
}
