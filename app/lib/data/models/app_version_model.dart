class AppVersionModel {
  static const int defaultVersionCode = 1;
  static const String defaultVersionName = '1.0.0';

  static int currentVersionCode = defaultVersionCode;
  static String currentVersionName = defaultVersionName;

  final String latestVersion;
  final int latestVersionCode;
  final int minRequiredVersionCode;
  final String updateUrl;
  final String title;
  final String releaseNotes;
  final bool forceUpdate;
  final int appVersionCode;
  final String appVersionName;

  AppVersionModel({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.minRequiredVersionCode,
    required this.updateUrl,
    required this.title,
    required this.releaseNotes,
    this.forceUpdate = false,
    int? appVersionCode,
    String? appVersionName,
  })  : appVersionCode = appVersionCode ?? currentVersionCode,
        appVersionName = appVersionName ?? currentVersionName;

  bool get isUpdateAvailable => latestVersionCode > appVersionCode;

  bool get isMandatory => forceUpdate || appVersionCode < minRequiredVersionCode;

  factory AppVersionModel.fromJson(
    Map<String, dynamic> json, {
    int? appVersionCode,
    String? appVersionName,
  }) {
    final effectiveAppCode = appVersionCode ?? currentVersionCode;
    final effectiveAppName = appVersionName ?? currentVersionName;

    return AppVersionModel(
      latestVersion: json['latestVersion']?.toString() ?? effectiveAppName,
      latestVersionCode: json['latestVersionCode'] is int
          ? json['latestVersionCode'] as int
          : int.tryParse(json['latestVersionCode']?.toString() ?? '1') ?? 1,
      minRequiredVersionCode: json['minRequiredVersionCode'] is int
          ? json['minRequiredVersionCode'] as int
          : int.tryParse(json['minRequiredVersionCode']?.toString() ?? '1') ?? 1,
      updateUrl: json['updateUrl']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Naya Update Uplabdh Hai! 🚀',
      releaseNotes: json['releaseNotes']?.toString() ??
          'Naye features aur performance improvements ke sath naya version uplabdh hai.',
      forceUpdate: json['forceUpdate'] == true,
      appVersionCode: effectiveAppCode,
      appVersionName: effectiveAppName,
    );
  }
}
