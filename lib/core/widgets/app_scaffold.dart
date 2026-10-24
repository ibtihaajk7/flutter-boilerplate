import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';

/// Every screen starts here: safe area and page padding are handled once,
/// so screens never add `SafeArea` ad hoc.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: body,
        ),
      ),
    );
  }
}
