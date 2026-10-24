import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_route_observer.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/l10n/l10n.dart';
import 'package:flutter_boilerplate/core/scale/app_scale.dart';
import 'package:flutter_boilerplate/core/theme/app_theme.dart';
import 'package:flutter_boilerplate/features/home/home_page.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Largest system text scale the layouts are designed to absorb.
///
/// Accessibility still works up to this point; beyond it, text would push
/// fixed layouts off screen on small phones.
const double maxTextScaleFactor = 1.3;

class App extends StatefulWidget {
  const App({super.key, this.locale});

  /// Forces a locale (tests, or a user-picked language). `null` follows the
  /// device.
  final Locale? locale;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // slim:analytics:start
  late final AnalyticsRouteObserver _routeObserver = AnalyticsRouteObserver(
    context.read<AnalyticsService>(),
  );
  // slim:analytics:end

  @override
  Widget build(BuildContext context) {
    // Must run before the theme is built: theme text sizes come from
    // SafeScale. Rebuilds here on rotation / resize re-scale the whole app.
    initSafeScale(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appTitle,
      navigatorObservers: [
        _routeObserver, // slim:analytics
      ],
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              maxScaleFactor: maxTextScaleFactor,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomePage(),
    );
  }
}
