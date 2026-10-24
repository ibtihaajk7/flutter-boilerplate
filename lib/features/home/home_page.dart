import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/l10n/l10n.dart';
import 'package:flutter_boilerplate/core/layout/breakpoints.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';
import 'package:flutter_boilerplate/core/widgets/app_scaffold.dart';
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_boilerplate/features/home/notification_card.dart';
import 'package:provider/provider.dart';

/// Example screen built the AGENTS.md way: Columns and Rows (no Stack),
/// spacing from `AppSpacing`, text from the theme, strings from l10n, and a
/// layout that picks itself from the space it gets.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.homeTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: context.read<CounterController>().increment,
        tooltip: l10n.incrementTooltip,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet =
              ScreenType.fromWidth(constraints.maxWidth) == ScreenType.tablet;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.lg,
                    children: [
                      const Expanded(child: _IntroCard()),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.md,
                          children: const [_CounterCard(), NotificationCard()],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.md,
                    children: const [
                      _IntroCard(),
                      _CounterCard(),
                      NotificationCard(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

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
            Text(l10n.welcomeHeadline, style: textTheme.headlineSmall),
            Text(l10n.welcomeBody, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final count = context.watch<CounterController>().count;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: Text(
                l10n.counterLabel(count),
                style: textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: count == 0
                  ? null
                  : context.read<CounterController>().reset,
              child: Text(l10n.reset),
            ),
          ],
        ),
      ),
    );
  }
}
