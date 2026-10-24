import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_events.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/l10n/l10n.dart';
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';
import 'package:provider/provider.dart';

/// Example of asking for notification permission in context (when the user
/// taps), never on launch.
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key});

  static const int testNotificationId = 1;

  Future<void> _sendTest(BuildContext context) async {
    final l10n = context.l10n;
    final notifications = context.read<LocalNotificationService>();
    final messenger = ScaffoldMessenger.of(context);
    // slim:analytics:start
    context.read<AnalyticsService>().track(AnalyticsEvents.buttonTap, {
      AnalyticsParams.buttonName: 'send_test_notification',
    }).ignore();
    // slim:analytics:end

    if (!await notifications.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.notificationsDenied)));
      return;
    }
    await notifications.show(
      id: testNotificationId,
      title: l10n.testNotificationTitle,
      body: l10n.testNotificationBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(l10n.notificationsTitle, style: textTheme.titleMedium),
            Text(l10n.notificationsBody, style: textTheme.bodyMedium),
            FilledButton.tonal(
              onPressed: () => _sendTest(context),
              child: Text(l10n.sendTestNotification),
            ),
          ],
        ),
      ),
    );
  }
}
