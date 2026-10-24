// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get welcomeHeadline => 'Bienvenue';

  @override
  String get welcomeBody =>
      'Cet écran est construit avec des Rows et des Columns, des tailles SafeScale et des textes localisés. Remplace-le par ta première fonctionnalité.';

  @override
  String counterLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Appuyé $count fois',
      one: 'Appuyé une fois',
      zero: 'Aucun appui pour l\'instant',
    );
    return '$_temp0';
  }

  @override
  String get incrementTooltip => 'Incrémenter';

  @override
  String get reset => 'Réinitialiser';
}
