import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/l10n/l10n.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;

  test('matches a supported language regardless of region', () {
    expect(
      resolveLocale(const Locale('fr', 'CA'), supported),
      const Locale('fr'),
    );
  });

  test('falls back to English for unsupported languages', () {
    expect(resolveLocale(const Locale('ja'), supported), const Locale('en'));
  });

  test('falls back to English when the device reports no locale', () {
    expect(resolveLocale(null, supported), const Locale('en'));
  });
}
