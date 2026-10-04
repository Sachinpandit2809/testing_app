import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationSettingsScreen
    extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen>
      createState() =>
          _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<
        NotificationSettingsScreen> {
  late TextEditingController
      _titleController;

  late TextEditingController
      _bodyController;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController();

    _bodyController =
        TextEditingController();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) async {
        final auth =
            context.read<AuthProvider>();

        final user =
            auth.user;

        if (user == null) {
          return;
        }

        final provider =
            context.read<
                NotificationProvider>();

        await provider.loadSettings(
          user.uid,
        );

        if (!mounted) {
          return;
        }

        _titleController.text =
            provider.settings.title;

        _bodyController.text =
            provider.settings.body;

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final auth =
        context.read<AuthProvider>();

    final user =
        auth.user;

    if (user == null) {
      return;
    }

    final provider =
        context.read<
            NotificationProvider>();

    final success =
        await provider.updateSettings(
      userId: user.uid,
      title:
          _titleController.text.trim(),
      body:
          _bodyController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Notification settings saved'
              : 'Could not save settings',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<
            NotificationProvider>();

    final settings =
        provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Notifications',
                  ),
                  subtitle: const Text(
                    'Receive notifications for new messages',
                  ),
                  value:
                      settings.enabled,
                  onChanged:
                      (value) async {
                    final auth =
                        context.read<
                            AuthProvider>();

                    final user =
                        auth.user;

                    if (user == null) {
                      return;
                    }

                    await provider
                        .updateSettings(
                      userId:
                          user.uid,
                      enabled:
                          value,
                    );
                  },
                ),

                const Divider(),

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Show message content',
                  ),
                  subtitle: const Text(
                    'Show the actual message in notification',
                  ),
                  value:
                      settings
                          .showMessageContent,
                  onChanged:
                      settings.enabled
                          ? (value) async {
                              final auth =
                                  context.read<
                                      AuthProvider>();

                              final user =
                                  auth.user;

                              if (user ==
                                  null) {
                                return;
                              }

                              await provider
                                  .updateSettings(
                                userId:
                                    user.uid,
                                showMessageContent:
                                    value,
                              );
                            }
                          : null,
                ),

                const SizedBox(
                  height: 20,
                ),

                TextField(
                  controller:
                      _titleController,
                  enabled:
                      settings.enabled,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Notification title',
                    hintText:
                        '💬 New Message',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                TextField(
                  controller:
                      _bodyController,
                  enabled:
                      settings.enabled,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Notification body',
                    hintText:
                        '{sender} sent you a message',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Available variables:',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  '{sender}  → sender name\n'
                  '{message} → message text\n'
                  '{type} → text / image / video',
                ),

                const SizedBox(
                  height: 24,
                ),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        settings.enabled
                            ? _save
                            : null,
                    child: const Text(
                      'Save Notification Settings',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                _buildPreview(
                  settings,
                ),
              ],
            ),
    );
  }

  Widget _buildPreview(
    dynamic settings,
  ) {
    String title =
        _titleController.text.isEmpty
            ? settings.title
            : _titleController.text;

    String body =
        _bodyController.text.isEmpty
            ? settings.body
            : _bodyController.text;

    body = body
        .replaceAll(
          '{sender}',
          'Sachin',
        )
        .replaceAll(
          '{message}',
          'Hey, are you free?',
        )
        .replaceAll(
          '{type}',
          'text',
        );

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(body),
          ],
        ),
      ),
    );
  }
}