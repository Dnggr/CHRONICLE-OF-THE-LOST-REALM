/// Player-facing preferences, persisted separately from story/save data
/// (see SaveManager - this lives in its own Hive box) so that wiping
/// your Chronicle in Settings never resets your text size or theme.
class AppSettings {
  /// Global text scale multiplier applied via MediaQuery in main.dart.
  /// 1.0 = default. Kept to a sane 0.85-1.3 range by the settings UI.
  double textScale;

  bool darkMode;

  /// Whether SceneScreen shows the "Roll: 14 + 2 = 16 vs DC 12" banner
  /// after a stat check, or just silently applies the outcome.
  bool showRollBanner;

  AppSettings({
    this.textScale = 1.0,
    this.darkMode = false,
    this.showRollBanner = true,
  });

  Map<String, dynamic> toJson() => {
        'textScale': textScale,
        'darkMode': darkMode,
        'showRollBanner': showRollBanner,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      darkMode: json['darkMode'] as bool? ?? false,
      showRollBanner: json['showRollBanner'] as bool? ?? true,
    );
  }
}
