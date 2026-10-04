import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final ImagePicker _picker =
      ImagePicker();

  static const int maxVideoSize =
      50 * 1024 * 1024;

  String getChatId(
    String userId1,
    String userId2,
  ) {
    final ids = [
      userId1,
      userId2,
    ];

    ids.sort();

    return '${ids[0]}_${ids[1]}';
  }

  // ============================================================
  // CREATE CHAT
  // ============================================================

  Future<void> createChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = getChatId(
      currentUserId,
      otherUserId,
    );

    final chatRef = _firestore
        .collection('chats')
        .doc(chatId);

    final snapshot =
        await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'participants': [
          currentUserId,
          otherUserId,
        ],
        'createdAt':
            DateTime.now().toIso8601String(),
        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSenderId': null,
        'typing': {
          currentUserId: false,
          otherUserId: false,
        },
      });
    } else {
      await chatRef.set(
        {
          'typing': {
            currentUserId: false,
            otherUserId: false,
          },
        },
        SetOptions(merge: true),
      );
    }
  }

  // ============================================================
  // SEND TEXT
  // ============================================================

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final messageText = text.trim();

    if (messageText.isEmpty) {
      return;
    }

    final chatId = getChatId(
      senderId,
      receiverId,
    );

    final chatRef = _firestore
        .collection('chats')
        .doc(chatId);

    final messageRef = chatRef
        .collection('messages')
        .doc();

    final now = DateTime.now();

    final message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: messageText,
      type: 'text',
      timestamp: now,
      seen: false,
      isDeleted: false,
    );

    await messageRef.set(
      message.toMap(),
    );

    await chatRef.set(
      {
        'lastMessage': messageText,
        'lastMessageTime':
            now.toIso8601String(),
        'lastMessageSenderId':
            senderId,
        'typing.$senderId': false,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
    );
  }

  // ============================================================
  // PICK VIDEO
  // ============================================================

  Future<XFile?> pickVideo() async {
    return await _picker.pickVideo(
      source: ImageSource.gallery,
    );
  }

  // ============================================================
  // UPLOAD FILE WITH REAL PROGRESS
  // ============================================================

  Future<void> _uploadFileWithProgress({
    required File file,
    required Reference storageRef,
    required void Function(double progress)
        onProgress,
  }) async {
    final UploadTask uploadTask =
        storageRef.putFile(file);

    final completer =
        Completer<void>();

    late StreamSubscription<
        TaskSnapshot> subscription;

    subscription =
        uploadTask.snapshotEvents.listen(
      (snapshot) {
        final total =
            snapshot.totalBytes;

        final transferred =
            snapshot.bytesTransferred;

        if (total > 0) {
          final progress =
              transferred / total;

          onProgress(
            progress.clamp(0.0, 1.0),
          );
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            error,
          );
        }
      },
    );

    try {
      await uploadTask;

      onProgress(1.0);

      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    } finally {
      await subscription.cancel();
    }

    await completer.future;
  }

  // ============================================================
  // SEND IMAGE
  // ============================================================

  Future<void> sendImage({
    required String senderId,
    required String receiverId,
    required XFile image,
    required void Function(double progress)
        onProgress,
  }) async {
    final file =
        File(image.path);

    final fileSize =
        await file.length();

    final fileName =
        image.name;

    final extension =
        fileName.contains('.')
            ? fileName
                .split('.')
                .last
                .toLowerCase()
            : 'jpg';

    final chatId =
        getChatId(
      senderId,
      receiverId,
    );

    final messageRef =
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

    final storageRef =
        _storage
            .ref()
            .child('chat_media')
            .child(chatId)
            .child('images')
            .child(
              '${messageRef.id}.$extension',
            );

    await _uploadFileWithProgress(
      file: file,
      storageRef: storageRef,
      onProgress: onProgress,
    );

    final mediaUrl =
        await storageRef
            .getDownloadURL();

    final now =
        DateTime.now();

    final message =
        MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: '',
      type: 'image',
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: now,
      seen: false,
      isDeleted: false,
    );

    await messageRef.set(
      message.toMap(),
    );

    await _updateLastMessage(
      chatId: chatId,
      senderId: senderId,
      lastMessage: '📷 Photo',
      time: now,
    );
  }

  // ============================================================
  // SEND VIDEO
  // ============================================================

  Future<void> sendVideo({
    required String senderId,
    required String receiverId,
    required XFile video,
    required void Function(double progress)
        onProgress,
    required void Function(double progress)
        onCompressionProgress,
  }) async {
    File videoFile =
        File(video.path);

    final originalSize =
        await videoFile.length();

    // ----------------------------------------------------------
    // VIDEO ALREADY BELOW 50 MB
    // ----------------------------------------------------------

    if (originalSize <=
        maxVideoSize) {
      await _uploadVideo(
        senderId: senderId,
        receiverId: receiverId,
        videoFile: videoFile,
        originalFileName: video.name,
        onProgress: onProgress,
      );

      return;
    }

    MediaInfo? compressedInfo;

    try {
      // --------------------------------------------------------
      // HIGHEST QUALITY
      // --------------------------------------------------------

      onCompressionProgress(0.10);

      compressedInfo =
          await VideoCompress.compressVideo(
        videoFile.path,
        quality:
            VideoQuality.HighestQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      onCompressionProgress(0.35);

      File? compressedFile =
          compressedInfo?.file;

      if (compressedFile != null) {
        final compressedSize =
            await compressedFile.length();

        if (compressedSize <=
            maxVideoSize) {
          await _uploadVideo(
            senderId: senderId,
            receiverId: receiverId,
            videoFile: compressedFile,
            originalFileName: video.name,
            onProgress: onProgress,
          );

          return;
        }
      }

      // --------------------------------------------------------
      // MEDIUM QUALITY
      // --------------------------------------------------------

      onCompressionProgress(0.45);

      compressedInfo =
          await VideoCompress.compressVideo(
        videoFile.path,
        quality:
            VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      onCompressionProgress(0.65);

      compressedFile =
          compressedInfo?.file;

      if (compressedFile != null) {
        final compressedSize =
            await compressedFile.length();

        if (compressedSize <=
            maxVideoSize) {
          await _uploadVideo(
            senderId: senderId,
            receiverId: receiverId,
            videoFile: compressedFile,
            originalFileName: video.name,
            onProgress: onProgress,
          );

          return;
        }
      }

      // --------------------------------------------------------
      // LOW QUALITY
      // --------------------------------------------------------

      onCompressionProgress(0.75);

      compressedInfo =
          await VideoCompress.compressVideo(
        videoFile.path,
        quality:
            VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 24,
      );

      onCompressionProgress(0.95);

      compressedFile =
          compressedInfo?.file;

      if (compressedFile != null) {
        final compressedSize =
            await compressedFile.length();

        if (compressedSize <=
            maxVideoSize) {
          await _uploadVideo(
            senderId: senderId,
            receiverId: receiverId,
            videoFile: compressedFile,
            originalFileName: video.name,
            onProgress: onProgress,
          );

          return;
        }
      }

      throw Exception(
        'This video is too large. '
        'Even after compression it is still above 50 MB.',
      );
    } finally {
      onCompressionProgress(1.0);

      await VideoCompress
          .deleteAllCache();
    }
  }

  // ============================================================
  // UPLOAD VIDEO
  // ============================================================

  Future<void> _uploadVideo({
    required String senderId,
    required String receiverId,
    required File videoFile,
    required String originalFileName,
    required void Function(double progress)
        onProgress,
  }) async {
    final finalSize =
        await videoFile.length();

    if (finalSize > maxVideoSize) {
      throw Exception(
        'Video must be 50 MB or smaller.',
      );
    }

    final chatId =
        getChatId(
      senderId,
      receiverId,
    );

    final messageRef =
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

    final storageRef =
        _storage
            .ref()
            .child('chat_media')
            .child(chatId)
            .child('videos')
            .child(
              '${messageRef.id}.mp4',
            );

    await _uploadFileWithProgress(
      file: videoFile,
      storageRef: storageRef,
      onProgress: onProgress,
    );

    final mediaUrl =
        await storageRef
            .getDownloadURL();

    final now =
        DateTime.now();

    final message =
        MessageModel(
      id: messageRef.id,
      senderId: senderId,
      receiverId: receiverId,
      text: '',
      type: 'video',
      mediaUrl: mediaUrl,
      fileName: originalFileName,
      fileSize: finalSize,
      timestamp: now,
      seen: false,
      isDeleted: false,
    );

    await messageRef.set(
      message.toMap(),
    );

    await _updateLastMessage(
      chatId: chatId,
      senderId: senderId,
      lastMessage: '🎥 Video',
      time: now,
    );
  }

  // ============================================================
  // LAST MESSAGE
  // ============================================================

  Future<void> _updateLastMessage({
    required String chatId,
    required String senderId,
    required String lastMessage,
    required DateTime time,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(
      {
        'lastMessage':
            lastMessage,
        'lastMessageTime':
            time.toIso8601String(),
        'lastMessageSenderId':
            senderId,
        'typing.$senderId':
            false,
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // GET MESSAGES
  // ============================================================

  Stream<List<MessageModel>> getMessages({
    required String currentUserId,
    required String otherUserId,
  }) {
    final chatId =
        getChatId(
      currentUserId,
      otherUserId,
    );

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: false,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (doc) =>
                  MessageModel.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();
      },
    );
  }

  // ============================================================
  // GET USER
  // ============================================================

  Future<UserModel?> getUserById(
    String uid,
  ) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    return UserModel.fromMap(data);
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> deleteMessage({
    required String currentUserId,
    required String otherUserId,
    required String messageId,
  }) async {
    final chatId =
        getChatId(
      currentUserId,
      otherUserId,
    );

    final messageRef =
        _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);

    await messageRef.update({
      'isDeleted': true,
    });
  }

  // ============================================================
  // READ RECEIPTS
  // ============================================================

  Future<void> markMessagesAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId =
        getChatId(
      currentUserId,
      otherUserId,
    );

    final snapshot =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where(
              'receiverId',
              isEqualTo: currentUserId,
            )
            .where(
              'seen',
              isEqualTo: false,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch =
        _firestore.batch();

    for (final doc
        in snapshot.docs) {
      batch.update(
        doc.reference,
        {
          'seen': true,
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // TYPING
  // ============================================================

  Future<void> setTyping({
    required String currentUserId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    final chatId =
        getChatId(
      currentUserId,
      otherUserId,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .set(
      {
        'typing.$currentUserId':
            isTyping,
      },
      SetOptions(merge: true),
    );
  }

  Stream<bool> getTypingStatus({
    required String currentUserId,
    required String otherUserId,
  }) {
    final chatId =
        getChatId(
      currentUserId,
      otherUserId,
    );

    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map(
      (snapshot) {
        if (!snapshot.exists) {
          return false;
        }

        final data =
            snapshot.data();

        if (data == null) {
          return false;
        }

        final typing =
            data['typing']
                as Map<String, dynamic>?;

        if (typing == null) {
          return false;
        }

        return typing[otherUserId] ==
            true;
      },
    );
  }
}