import 'media_kind.dart';

/// Primary key used by the "Sort by" list.
enum SortField { name, size, date, duration }

/// Secondary key used by the "Sort order" list.
enum SortOrder { ascending, descending }

enum AppThemeMode { system, light, dark }

extension SortFieldX on SortField {
  String get label {
    switch (this) {
      case SortField.name:
        return 'Name';
      case SortField.size:
        return 'Size';
      case SortField.date:
        return 'Date';
      case SortField.duration:
        return 'Duration';
    }
  }

  /// Duration is only meaningful for videos and audio.
  bool supports(MediaKind kind) =>
      this != SortField.duration || kind != MediaKind.image;
}

extension SortOrderX on SortOrder {
  String get label => this == SortOrder.ascending ? 'Ascending' : 'Descending';

  /// Human explanation of the direction for the chosen field.
  String hint(SortField field) {
    final asc = this == SortOrder.ascending;
    switch (field) {
      case SortField.name:
        return asc ? 'A → Z' : 'Z → A';
      case SortField.size:
        return asc ? 'Smallest first' : 'Largest first';
      case SortField.date:
        return asc ? 'Oldest first' : 'Newest first';
      case SortField.duration:
        return asc ? 'Shortest first' : 'Longest first';
    }
  }
}

extension AppThemeModeX on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}

SortField parseSortField(String? value, SortField fallback) {
  for (final field in SortField.values) {
    if (field.name == value) return field;
  }
  return fallback;
}

SortOrder parseSortOrder(String? value, SortOrder fallback) {
  for (final order in SortOrder.values) {
    if (order.name == value) return order;
  }
  return fallback;
}

AppThemeMode parseThemeMode(String? value, AppThemeMode fallback) {
  for (final mode in AppThemeMode.values) {
    if (mode.name == value) return mode;
  }
  return fallback;
}

/// Everything the user can customise, persisted in SQLite.
///
/// Sort options are kept per media kind so that changing the photo order does
/// not silently reorder the music list.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.gridColumns,
    required this.sortFields,
    required this.sortOrders,
  });

  factory AppSettings.defaults() => const AppSettings(
        themeMode: AppThemeMode.system,
        gridColumns: 3,
        sortFields: {
          MediaKind.image: SortField.date,
          MediaKind.video: SortField.date,
          MediaKind.audio: SortField.name,
        },
        sortOrders: {
          MediaKind.image: SortOrder.descending,
          MediaKind.video: SortOrder.descending,
          MediaKind.audio: SortOrder.ascending,
        },
      );

  final AppThemeMode themeMode;
  final int gridColumns;
  final Map<MediaKind, SortField> sortFields;
  final Map<MediaKind, SortOrder> sortOrders;

  SortField fieldFor(MediaKind kind) =>
      sortFields[kind] ?? AppSettings.defaults().sortFields[kind]!;

  SortOrder orderFor(MediaKind kind) =>
      sortOrders[kind] ?? AppSettings.defaults().sortOrders[kind]!;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? gridColumns,
    Map<MediaKind, SortField>? sortFields,
    Map<MediaKind, SortOrder>? sortOrders,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      gridColumns: gridColumns ?? this.gridColumns,
      sortFields: sortFields ?? this.sortFields,
      sortOrders: sortOrders ?? this.sortOrders,
    );
  }

  AppSettings withSort(MediaKind kind, SortField field, SortOrder order) {
    return copyWith(
      sortFields: {...sortFields, kind: field},
      sortOrders: {...sortOrders, kind: order},
    );
  }
}
