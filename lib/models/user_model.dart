class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  final bool notificationsEnabled;
  final bool showMessageContent;
  final String notificationTitle;
  final String notificationBody;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.notificationsEnabled = true,
    this.showMessageContent = true,
    this.notificationTitle = '💬 New Message',
    this.notificationBody = '{sender} sent you a message',
    this.fcmTokens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),

      'notificationsEnabled': notificationsEnabled,
      'showMessageContent': showMessageContent,
      'notificationTitle': notificationTitle,
      'notificationBody': notificationBody,
      'fcmTokens': fcmTokens,
    };
  }

  factory UserModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final dynamic tokensData =
        map['fcmTokens'];

    List<String> tokens = [];

    if (tokensData is List) {
      tokens = tokensData
          .map(
            (token) => token.toString(),
          )
          .toList();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],

      isOnline:
          map['isOnline'] ?? false,

      lastSeen:
          map['lastSeen'] != null
              ? DateTime.tryParse(
                  map['lastSeen'].toString(),
                )
              : null,

      notificationsEnabled:
          map['notificationsEnabled'] ??
              true,

      showMessageContent:
          map['showMessageContent'] ??
              true,

      notificationTitle:
          map['notificationTitle'] ??
              '💬 New Message',

      notificationBody:
          map['notificationBody'] ??
              '{sender} sent you a message',

      fcmTokens: tokens,
    );
  }
}