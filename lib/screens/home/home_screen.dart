import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testing_app/screens/chat/chat_screen.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../auth/login_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final NotificationService
  //   _notificationService =
  //   NotificationService();
    
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          context.read<AuthProvider>();

      final currentUser = authProvider.user;

      if (currentUser != null) {
        context
            .read<ChatProvider>()
            .listenToUsers(currentUser.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();

    final chatProvider =
        context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),

        actions: [
          IconButton(
            onPressed: () async {
              await context
                  .read<AuthProvider>()
                  .logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: _buildBody(
        context,
        authProvider,
        chatProvider,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    if (chatProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatProvider.errorMessage != null) {
      return Center(
        child: Text(
          chatProvider.errorMessage!,
        ),
      );
    }

    if (chatProvider.users.isEmpty) {
      return const Center(
        child: Text(
          'No other users found.',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: chatProvider.users.length,

      itemBuilder: (context, index) {
        final user = chatProvider.users[index];

        return ListTile(
          leading: CircleAvatar(
            radius: 25,

            child: Text(
              user.name.isNotEmpty
                  ? user.name[0].toUpperCase()
                  : '?',
            ),
          ),

          title: Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          subtitle: Row(
            children: [
              Container(
                width: 8,
                height: 8,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.isOnline
                      ? Colors.green
                      : Colors.grey,
                ),
              ),

              const SizedBox(width: 6),

              Text(
                user.isOnline
                    ? 'Online'
                    : 'Offline',
              ),
            ],
          ),

          onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(
        otherUser: user,
      ),
    ),
  );
},
        );
      },
    );
  }
}