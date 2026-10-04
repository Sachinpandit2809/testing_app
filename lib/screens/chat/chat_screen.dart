import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  Timer? _typingTimer;

  bool _isCurrentlyTyping = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          context.read<AuthProvider>();

      final currentUser =
          authProvider.user;

      if (currentUser == null) {
        return;
      }

      final chatProvider =
          context.read<ChatProvider>();

      chatProvider.openChat(
        currentUserId: currentUser.uid,
        otherUserId: widget.otherUser.uid,
      );

      chatProvider.listenToMessages(
        currentUserId: currentUser.uid,
        otherUserId: widget.otherUser.uid,
      );

      chatProvider.markMessagesAsRead(
        currentUserId: currentUser.uid,
        otherUserId: widget.otherUser.uid,
      );

      chatProvider.listenToTyping(
        currentUserId: currentUser.uid,
        otherUserId: widget.otherUser.uid,
      );
    });
  }

  // ============================================================
  // TYPING
  // ============================================================

  void _onTextChanged(String value) {
    final currentUser =
        context.read<AuthProvider>().user;

    if (currentUser == null) {
      return;
    }

    final chatProvider =
        context.read<ChatProvider>();

    final hasText =
        value.trim().isNotEmpty;

    if (hasText && !_isCurrentlyTyping) {
      _isCurrentlyTyping = true;

      chatProvider.setTyping(
        currentUserId: currentUser.uid,
        otherUserId: widget.otherUser.uid,
        isTyping: true,
      );
    }

    _typingTimer?.cancel();

    if (!hasText) {
      _isCurrentlyTyping = false;

      chatProvider.setTyping(
        currentUserId: currentUser.uid,
        otherUserId: widget.otherUser.uid,
        isTyping: false,
      );

      return;
    }

    _typingTimer = Timer(
      const Duration(milliseconds: 1500),
      () {
        if (!mounted) {
          return;
        }

        final currentUser =
            context.read<AuthProvider>().user;

        if (currentUser == null) {
          return;
        }

        _isCurrentlyTyping = false;

        context.read<ChatProvider>().setTyping(
              currentUserId: currentUser.uid,
              otherUserId: widget.otherUser.uid,
              isTyping: false,
            );
      },
    );
  }

  void _stopTyping() {
    if (!_isCurrentlyTyping) {
      return;
    }

    final currentUser =
        context.read<AuthProvider>().user;

    if (currentUser == null) {
      return;
    }

    _isCurrentlyTyping = false;

    context.read<ChatProvider>().setTyping(
          currentUserId: currentUser.uid,
          otherUserId: widget.otherUser.uid,
          isTyping: false,
        );
  }

  // ============================================================
  // SEND TEXT
  // ============================================================

  Future<void> _sendMessage() async {
    final text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final currentUser =
        context.read<AuthProvider>().user;

    if (currentUser == null) {
      return;
    }

    _stopTyping();

    final chatProvider =
        context.read<ChatProvider>();

    final success =
        await chatProvider.sendMessage(
      senderId: currentUser.uid,
      receiverId: widget.otherUser.uid,
      text: text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            chatProvider.errorMessage ??
                'Message could not be sent.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    final currentUser =
        context.read<AuthProvider>().user;

    if (currentUser == null) {
      return;
    }

    final chatProvider =
        context.read<ChatProvider>();

    final XFile? image =
        await chatProvider.pickImage();

    if (image == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final success =
        await chatProvider.sendImage(
      senderId: currentUser.uid,
      receiverId: widget.otherUser.uid,
      image: image,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            chatProvider.errorMessage ??
                'Image could not be sent.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PICK VIDEO
  // ============================================================

  Future<void> _pickVideo() async {
    final currentUser =
        context.read<AuthProvider>().user;

    if (currentUser == null) {
      return;
    }

    final chatProvider =
        context.read<ChatProvider>();

    final XFile? video =
        await chatProvider.pickVideo();

    if (video == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final success =
        await chatProvider.sendVideo(
      senderId: currentUser.uid,
      receiverId: widget.otherUser.uid,
      video: video,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            chatProvider.errorMessage ??
                'Video could not be sent.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ATTACHMENT MENU
  // ============================================================

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(
                  icon: Icons.photo,
                  label: 'Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _attachmentOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              child: Icon(
                icon,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> _deleteMessage(
    MessageModel message,
  ) async {
    final currentUser =
        context.read<AuthProvider>().user;

    if (currentUser == null) {
      return;
    }

    if (message.senderId !=
        currentUser.uid) {
      return;
    }

    if (message.isDeleted) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete message?',
          ),
          content: const Text(
            'This message will be removed from the chat view.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final success =
        await context
            .read<ChatProvider>()
            .deleteMessage(
      currentUserId:
          currentUser.uid,
      otherUserId:
          widget.otherUser.uid,
      messageId:
          message.id,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete message.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // IMAGE MESSAGE
  // ============================================================

  Widget _buildImageMessage(
    MessageModel message,
    bool isMe,
  ) {
    if (message.mediaUrl == null ||
        message.mediaUrl!.isEmpty) {
      return _buildMediaError(
        isMe,
        'Image unavailable',
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Image.network(
        message.mediaUrl!,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder:
            (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return const SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return _buildMediaError(
            isMe,
            'Could not load image',
          );
        },
      ),
    );
  }

  // ============================================================
  // VIDEO MESSAGE
  // ============================================================

  Widget _buildVideoMessage(
    MessageModel message,
    bool isMe,
  ) {
    if (message.mediaUrl == null ||
        message.mediaUrl!.isEmpty) {
      return _buildMediaError(
        isMe,
        'Video unavailable',
      );
    }

    return _VideoMessageWidget(
      videoUrl: message.mediaUrl!,
    );
  }

  Widget _buildMediaError(
    bool isMe,
    String text,
  ) {
    return Container(
      width: 220,
      height: 160,
      alignment:
          Alignment.center,
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white24
            : Colors.grey.shade300,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign:
            TextAlign.center,
        style: TextStyle(
          color: isMe
              ? Colors.white
              : Colors.black54,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE CONTENT
  // ============================================================

  Widget _buildMessageContent(
    MessageModel message,
    bool isMe,
  ) {
    if (message.isText) {
      return Text(
        message.text,
        style: TextStyle(
          color: isMe
              ? Colors.white
              : Colors.black,
          fontSize: 16,
        ),
      );
    }

    if (message.isImage) {
      return _buildImageMessage(
        message,
        isMe,
      );
    }

    if (message.isVideo) {
      return _buildVideoMessage(
        message,
        isMe,
      );
    }

    return Text(
      'Unsupported message',
      style: TextStyle(
        color: isMe
            ? Colors.white
            : Colors.black,
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(
    MessageModel message,
    String currentUserId,
  ) {
    final isMe =
        message.senderId ==
            currentUserId;

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            isMe && !message.isDeleted
                ? () {
                    _deleteMessage(
                      message,
                    );
                  }
                : null,
        child: Container(
          margin:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          padding:
              message.isDeleted
                  ? const EdgeInsets
                      .symmetric(
                      horizontal: 14,
                      vertical: 9,
                    )
                  : const EdgeInsets.all(6),
          constraints:
              BoxConstraints(
            maxWidth:
                MediaQuery.of(context)
                        .size
                        .width *
                    0.78,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.blue
                : Colors.grey.shade200,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: message.isDeleted
              ? _buildDeletedMessage(
                  isMe,
                )
              : _buildMessageWithMeta(
                  message,
                  isMe,
                ),
        ),
      ),
    );
  }

  Widget _buildMessageWithMeta(
    MessageModel message,
    bool isMe,
  ) {
    return Column(
      mainAxisSize:
          MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        _buildMessageContent(
          message,
          isMe,
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              _formatTime(
                message.timestamp,
              ),
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(
                message.seen
                    ? Icons.done_all
                    : Icons.done,
                size: 16,
                color: message.seen
                    ? Colors.lightBlueAccent
                    : Colors.white70,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDeletedMessage(
    bool isMe,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          Icons.block,
          size: 16,
          color: isMe
              ? Colors.white70
              : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          'This message was deleted',
          style: TextStyle(
            fontSize: 14,
            fontStyle:
                FontStyle.italic,
            color: isMe
                ? Colors.white70
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TYPING INDICATOR
  // ============================================================

  Widget _buildTypingIndicator(
    bool isTyping,
  ) {
    if (!isTyping) {
      return const SizedBox(
        height: 8,
      );
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        left: 16,
        bottom: 8,
      ),
      child: Align(
        alignment:
            Alignment.centerLeft,
        child: Text(
          '${widget.otherUser.name} is typing...',
          style: TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 13,
            fontStyle:
                FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UPLOAD INDICATOR
  // ============================================================

Widget _buildUploadIndicator(
  ChatProvider provider,
) {
  if (!provider.isUploading) {
    return const SizedBox.shrink();
  }

  final progress = provider.isCompressing
      ? provider.compressionProgress
      : provider.uploadProgress;

  final percentage =
      (progress * 100).round();

  return Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                value: progress > 0
                    ? progress
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                provider.isCompressing
                    ? 'Compressing video... $percentage%'
                    : 'Uploading... $percentage%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress > 0
              ? progress
              : null,
        ),
      ],
    ),
  );
}
  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    DateTime? timestamp,
  ) {
    if (timestamp == null) {
      return '';
    }

    final hour =
        timestamp.hour == 0
            ? 12
            : timestamp.hour > 12
                ? timestamp.hour - 12
                : timestamp.hour;

    final minute =
        timestamp.minute
            .toString()
            .padLeft(2, '0');

    final period =
        timestamp.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController
          .hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent,
        duration:
            const Duration(
          milliseconds: 300,
        ),
        curve:
            Curves.easeOut,
      );
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _typingTimer?.cancel();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final authProvider =
        context.watch<AuthProvider>();

    final chatProvider =
        context.watch<ChatProvider>();

    final currentUser =
        authProvider.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User not logged in',
          ),
        ),
      );
    }

    final messages =
        chatProvider.messages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                widget.otherUser.name
                        .isNotEmpty
                    ? widget.otherUser
                        .name[0]
                        .toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  if (chatProvider
                      .isOtherUserTyping)
                    const Text(
                      'typing...',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.green,
                      ),
                    )
                  else
                    Text(
                      widget.otherUser
                              .isOnline
                          ? 'Online'
                          : 'Offline',
                      style:
                          const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                    ),
                  )
                : ListView.builder(
                    controller:
                        _scrollController,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 10,
                    ),
                    itemCount:
                        messages.length,
                    itemBuilder:
                        (context, index) {
                      final message =
                          messages[index];

                      return _buildMessageBubble(
                        message,
                        currentUser.uid,
                      );
                    },
                  ),
          ),

          _buildTypingIndicator(
            chatProvider
                .isOtherUserTyping,
          ),

          _buildUploadIndicator(
            chatProvider,
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(8),
              child: Row(
                children: [
                  // ATTACHMENT BUTTON
                  IconButton(
                    onPressed:
                        chatProvider
                                .isUploading
                            ? null
                            : _showAttachmentMenu,
                    icon: const Icon(
                      Icons.attach_file,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      controller:
                          _messageController,
                      onChanged:
                          _onTextChanged,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Type a message...',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            25,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  CircleAvatar(
                    radius: 25,
                    child: IconButton(
                      onPressed:
                          chatProvider
                                  .isUploading
                              ? null
                              : _sendMessage,
                      icon:
                          const Icon(
                        Icons.send,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// VIDEO MESSAGE WIDGET
// ================================================================

class _VideoMessageWidget
    extends StatefulWidget {
  final String videoUrl;

  const _VideoMessageWidget({
    required this.videoUrl,
  });

  @override
  State<_VideoMessageWidget>
      createState() =>
          _VideoMessageWidgetState();
}

class _VideoMessageWidgetState
    extends State<
        _VideoMessageWidget> {
  late VideoPlayerController
      _controller;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController
            .networkUrl(
      Uri.parse(
        widget.videoUrl,
      ),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller
          .initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint(
        'Video initialization error: $e',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!_initialized) {
      return Container(
        width: 220,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Stack(
        alignment:
            Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                    _controller
                        .value
                        .size
                        .width,
                height:
                    _controller
                        .value
                        .size
                        .height,
                child:
                    VideoPlayer(
                  _controller,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller
                    .value
                    .isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration:
                  const BoxDecoration(
                color:
                    Colors.black54,
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                _controller
                        .value
                        .isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color:
                    Colors.white,
                size: 35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}