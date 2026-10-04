import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/notification_settings_model.dart';

class NotificationProvider
    extends ChangeNotifier {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  NotificationSettingsModel
      _settings =
      const NotificationSettingsModel();

  bool _isLoading = false;

  bool get isLoading =>
      _isLoading;

  NotificationSettingsModel
      get settings =>
          _settings;

  Future<void> loadSettings(
    String userId,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .get();

      if (!doc.exists) {
        _settings =
            const NotificationSettingsModel();

        return;
      }

      final data =
          doc.data();

      if (data == null) {
        return;
      }

      _settings =
          NotificationSettingsModel(
        enabled:
            data[
                    'notificationsEnabled'] ??
                true,
        showMessageContent:
            data[
                    'showMessageContent'] ??
                true,
        title:
            data[
                    'notificationTitle'] ??
                '💬 New Message',
        body:
            data[
                    'notificationBody'] ??
                '{sender} sent you a message',
      );
    } catch (e) {
      debugPrint(
        'Load notification settings error: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings({
    required String userId,
    bool? enabled,
    bool? showMessageContent,
    String? title,
    String? body,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newSettings =
          _settings.copyWith(
        enabled: enabled,
        showMessageContent:
            showMessageContent,
        title: title,
        body: body,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(
        newSettings.toMap(),
        SetOptions(
          merge: true,
        ),
      );

      _settings =
          newSettings;

      return true;
    } catch (e) {
      debugPrint(
        'Update notification settings error: $e',
      );

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}