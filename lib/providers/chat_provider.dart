import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ChatService _chatService =
      ChatService();

  List<UserModel> _users = [];

  List<MessageModel> _messages = [];

  bool _isLoading = false;

  bool _isOtherUserTyping = false;

  bool _isUploading = false;

  double _uploadProgress = 0.0;

  double _compressionProgress = 0.0;

  bool _isCompressing = false;

  String? _errorMessage;

  StreamSubscription? _usersSubscription;

  StreamSubscription? _messagesSubscription;

  StreamSubscription? _typingSubscription;

  List<UserModel> get users =>
      _users;

  List<MessageModel> get messages =>
      _messages;

  bool get isLoading =>
      _isLoading;

  bool get isOtherUserTyping =>
      _isOtherUserTyping;

  bool get isUploading =>
      _isUploading;

  double get uploadProgress =>
      _uploadProgress;

  double get compressionProgress =>
      _compressionProgress;

  bool get isCompressing =>
      _isCompressing;

  String? get errorMessage =>
      _errorMessage;

  // ============================================================
  // USERS
  // ============================================================

  void listenToUsers(
    String currentUserId,
  ) {
    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    _usersSubscription?.cancel();

    _usersSubscription =
        _firestore
            .collection('users')
            .snapshots()
            .listen(
      (snapshot) {
        try {
          _users = snapshot.docs
              .where(
                (doc) =>
                    doc.id !=
                    currentUserId,
              )
              .map(
                (doc) =>
                    UserModel.fromMap(
                  doc.data(),
                ),
              )
              .toList();

          _isLoading = false;

          notifyListeners();
        } catch (e) {
          _errorMessage =
              e.toString();

          _isLoading = false;

          notifyListeners();
        }
      },
      onError: (error) {
        _errorMessage =
            error.toString();

        _isLoading = false;

        notifyListeners();
      },
    );
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  Future<void> openChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      await _chatService
          .createChat(
        currentUserId:
            currentUserId,
        otherUserId:
            otherUserId,
      );
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void listenToMessages({
    required String currentUserId,
    required String otherUserId,
  }) {
    _messages = [];

    _messagesSubscription?.cancel();

    _messagesSubscription =
        _chatService
            .getMessages(
              currentUserId:
                  currentUserId,
              otherUserId:
                  otherUserId,
            )
            .listen(
      (messages) {
        _messages =
            messages;

        notifyListeners();
      },
      onError: (error) {
        _errorMessage =
            error.toString();

        notifyListeners();
      },
    );
  }

  // ============================================================
  // SEND TEXT
  // ============================================================

  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return false;
    }

    try {
      await _chatService
          .sendMessage(
        senderId: senderId,
        receiverId:
            receiverId,
        text: text,
      );

      return true;
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<XFile?> pickImage() async {
    try {
      return await _chatService
          .pickImage();
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // PICK VIDEO
  // ============================================================

  Future<XFile?> pickVideo() async {
    try {
      return await _chatService
          .pickVideo();
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // SEND IMAGE
  // ============================================================

  Future<bool> sendImage({
    required String senderId,
    required String receiverId,
    required XFile image,
  }) async {
    try {
      _isUploading = true;

      _uploadProgress = 0.0;

      _isCompressing = false;

      _compressionProgress = 0.0;

      _errorMessage = null;

      notifyListeners();

      await _chatService.sendImage(
        senderId: senderId,
        receiverId: receiverId,
        image: image,
        onProgress: (progress) {
          _uploadProgress =
              progress;

          notifyListeners();
        },
      );

      _uploadProgress = 1.0;

      return true;
    } catch (e) {
      _errorMessage =
          e.toString();

      return false;
    } finally {
      _isUploading = false;

      _uploadProgress = 0.0;

      _isCompressing = false;

      _compressionProgress = 0.0;

      notifyListeners();
    }
  }

  // ============================================================
  // SEND VIDEO
  // ============================================================

  Future<bool> sendVideo({
    required String senderId,
    required String receiverId,
    required XFile video,
  }) async {
    try {
      _isUploading = true;

      _uploadProgress = 0.0;

      _isCompressing = false;

      _compressionProgress = 0.0;

      _errorMessage = null;

      notifyListeners();

      await _chatService.sendVideo(
        senderId: senderId,
        receiverId: receiverId,
        video: video,

        onProgress: (progress) {
          _isCompressing = false;

          _uploadProgress =
              progress;

          notifyListeners();
        },

        onCompressionProgress:
            (progress) {
          _isCompressing =
              progress < 1.0;

          _compressionProgress =
              progress;

          notifyListeners();
        },
      );

      _uploadProgress = 1.0;

      return true;
    } catch (e) {
      _errorMessage =
          e.toString();

      return false;
    } finally {
      _isUploading = false;

      _uploadProgress = 0.0;

      _isCompressing = false;

      _compressionProgress = 0.0;

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> deleteMessage({
    required String currentUserId,
    required String otherUserId,
    required String messageId,
  }) async {
    try {
      await _chatService
          .deleteMessage(
        currentUserId:
            currentUserId,
        otherUserId:
            otherUserId,
        messageId:
            messageId,
      );

      return true;
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<void> markMessagesAsRead({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      await _chatService
          .markMessagesAsRead(
        currentUserId:
            currentUserId,
        otherUserId:
            otherUserId,
      );

      _messages =
          _messages.map(
        (message) {
          if (message.receiverId ==
                  currentUserId &&
              !message.seen) {
            return MessageModel(
              id: message.id,
              senderId:
                  message.senderId,
              receiverId:
                  message.receiverId,
              text: message.text,
              type: message.type,
              mediaUrl:
                  message.mediaUrl,
              fileName:
                  message.fileName,
              fileSize:
                  message.fileSize,
              timestamp:
                  message.timestamp,
              seen: true,
              isDeleted:
                  message.isDeleted,
            );
          }

          return message;
        },
      ).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();
    }
  }

  // ============================================================
  // TYPING
  // ============================================================

  Future<void> setTyping({
    required String currentUserId,
    required String otherUserId,
    required bool isTyping,
  }) async {
    try {
      await _chatService
          .setTyping(
        currentUserId:
            currentUserId,
        otherUserId:
            otherUserId,
        isTyping:
            isTyping,
      );
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();
    }
  }

  void listenToTyping({
    required String currentUserId,
    required String otherUserId,
  }) {
    _typingSubscription?.cancel();

    _typingSubscription =
        _chatService
            .getTypingStatus(
              currentUserId:
                  currentUserId,
              otherUserId:
                  otherUserId,
            )
            .listen(
      (isTyping) {
        _isOtherUserTyping =
            isTyping;

        notifyListeners();
      },
      onError: (error) {
        _isOtherUserTyping =
            false;

        _errorMessage =
            error.toString();

        notifyListeners();
      },
    );
  }

  // ============================================================
  // GET USER
  // ============================================================

  Future<UserModel?> getUserById(
    String uid,
  ) async {
    try {
      return await _chatService
          .getUserById(uid);
    } catch (e) {
      _errorMessage =
          e.toString();

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage =
        null;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _usersSubscription?.cancel();

    _messagesSubscription?.cancel();

    _typingSubscription?.cancel();

    super.dispose();
  }
}