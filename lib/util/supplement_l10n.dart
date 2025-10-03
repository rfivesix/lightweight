// lib/util/supplement_l10n.dart
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/supplement.dart';

String localizeSupplementName(Supplement s, AppLocalizations l10n) {
  switch (s.code) {
    case 'caffeine':
      return l10n.supplement_caffeine;
    case 'creatine_monohydrate':
      return l10n.supplement_creatine_monohydrate;
    default:
      return s.name;
  }
}
