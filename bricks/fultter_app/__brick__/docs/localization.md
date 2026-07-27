# Localization

The generated app uses Flutter's `gen-l10n` tooling. English is the fallback
locale and Simplified Chinese is included as the reference translation.

## Add a locale

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<locale>.arb`.
2. Set `@@locale` and translate every message while preserving message keys.
3. Run `flutter gen-l10n` (also run automatically by Flutter build commands).
4. Use `AppLocalizations.of(context)!` in widgets instead of string literals.
5. Add a widget test that selects the locale through `localeProvider`.

Use `ref.read(localeProvider.notifier).setLocale(locale)` to select a locale.
Pass `null` to return to the device locale. Unsupported locales fall back to
English.
