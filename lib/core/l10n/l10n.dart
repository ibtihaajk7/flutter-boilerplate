import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Shorthand for `AppLocalizations.of(context)`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Picks the supported locale matching the device language, falling back to
/// English.
///
/// Never pass a raw device locale to `lookupAppLocalizations`: it throws for
/// unsupported languages. Resolve it through here first.
Locale resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  for (final supported in supportedLocales) {
    if (supported.languageCode == locale?.languageCode) {
      return supported;
    }
  }
  return const Locale('en');
}
