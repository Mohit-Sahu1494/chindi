class AppVersionModel {
  static const int currentVersionCode = 1;
  static const String currentVersionName = '1.0.0';

  final String latestVersion;
  final int latestVersionCode;
  final int minRequiredVersionCode;
  final String updateUrl;
  final String title;
  final String releaseNotes;
  final bool forceUpdate;

  const AppVersionModel({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.minRequiredVersionCode,
    required this.updateUrl,
    required this.title,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  bool get isUpdateAvailable => latestVersionCode > currentVersionCode;

  bool get isMandatory => forceUpdate || currentVersionCode < minRequiredVersionCode;

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      latestVersion: json['latestVersion']?.toString() ?? currentVersionName,
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
    );
  }
}
