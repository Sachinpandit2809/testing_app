class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;

  // Text message content.
  final String text;

  // text / image / video
  final String type;

  // Firebase Storage URL for image/video.
  final String? mediaUrl;

  // Original file name.
  final String? fileName;

  // File size in bytes.
  final int? fileSize;

  final DateTime? timestamp;
  final bool seen;

  // Soft delete.
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = 'text',
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.timestamp,
    this.seen = false,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'timestamp':
          timestamp?.toIso8601String(),
      'seen': seen,
      'isDeleted': isDeleted,
    };
  }

  factory MessageModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'] is int
          ? map['fileSize']
          : int.tryParse(
              map['fileSize']?.toString() ?? '',
            ),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(
              map['timestamp'].toString(),
            )
          : null,
      seen: map['seen'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  bool get isText => type == 'text';

  bool get isImage => type == 'image';

  bool get isVideo => type == 'video';
}