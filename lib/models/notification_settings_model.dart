class NotificationSettingsModel {
  final bool enabled;
  final bool showMessageContent;
  final String title;
  final String body;

  const NotificationSettingsModel({
    this.enabled = true,
    this.showMessageContent = true,
    this.title = '💬 New Message',
    this.body = '{sender} sent you a message',
  });

  NotificationSettingsModel copyWith({
    bool? enabled,
    bool? showMessageContent,
    String? title,
    String? body,
  }) {
    return NotificationSettingsModel(
      enabled:
          enabled ?? this.enabled,
      showMessageContent:
          showMessageContent ??
              this.showMessageContent,
      title:
          title ?? this.title,
      body:
          body ?? this.body,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled':
          enabled,
      'showMessageContent':
          showMessageContent,
      'notificationTitle':
          title,
      'notificationBody':
          body,
    };
  }
}