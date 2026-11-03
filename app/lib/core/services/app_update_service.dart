import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/api/api_client.dart';
import '../../data/models/app_version_model.dart';
import '../../features/auth/auth_provider.dart';
import '../widgets/update_dialog.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppUpdateService(apiClient);
});

final appVersionCheckProvider = FutureProvider.autoDispose<AppVersionModel?>((ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return await service.checkForUpdate();
});

class AppUpdateService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;
  static bool _dialogShowing = false;
  static const String dismissedVersionKey = 'chindi_dismissed_update_version_code';

  AppUpdateService(this._apiClient, [FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<AppVersionModel?> checkForUpdate() async {
    try {
      int currentCode = AppVersionModel.currentVersionCode;
      String currentName = AppVersionModel.currentVersionName;

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        if (packageInfo.version.isNotEmpty) {
          currentName = packageInfo.version;
        }
        final parsedCode = int.tryParse(packageInfo.buildNumber);
        if (parsedCode != null && parsedCode > 0) {
          currentCode = parsedCode;
        }
        AppVersionModel.currentVersionName = currentName;
        AppVersionModel.currentVersionCode = currentCode;
      } catch (e) {
        debugPrint('[AppUpdateService] PackageInfo note (using fallback): $e');
      }

      final res = await _apiClient.get('/version');
      if (res is Map<String, dynamic>) {
        final versionInfo = AppVersionModel.fromJson(
          res,
          appVersionCode: currentCode,
          appVersionName: currentName,
        );
        return versionInfo;
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking app version: $e');
    }
    return null;
  }

  /// Automatically displays the update popup if an update is available
  Future<void> checkAndShowUpdatePopup(BuildContext context) async {
    if (_dialogShowing) return;

    final versionInfo = await checkForUpdate();
    if (versionInfo == null || !versionInfo.isUpdateAvailable || !context.mounted) {
      return;
    }

    // If update is optional (not mandatory), check if user already dismissed this version
    if (!versionInfo.isMandatory) {
      try {
        final dismissedStr = await _storage.read(key: dismissedVersionKey);
        final dismissedCode = int.tryParse(dismissedStr ?? '');
        if (dismissedCode != null && dismissedCode >= versionInfo.latestVersionCode) {
          return;
        }
      } catch (e) {
        debugPrint('[AppUpdateService] Error reading dismissed version: $e');
      }
    }

    _dialogShowing = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: !versionInfo.isMandatory,
        builder: (ctx) => UpdateDialog(
          versionInfo: versionInfo,
          onUpdate: () async {
            if (!versionInfo.isMandatory) {
              await markVersionDismissed(versionInfo.latestVersionCode);
            }
            openUpdateUrl(versionInfo.updateUrl);
          },
          onDismiss: () async {
            if (!versionInfo.isMandatory) {
              await markVersionDismissed(versionInfo.latestVersionCode);
            }
          },
        ),
      );
      // Mark as dismissed if closed via barrier dismissal or back button
      if (!versionInfo.isMandatory) {
        await markVersionDismissed(versionInfo.latestVersionCode);
      }
    } finally {
      _dialogShowing = false;
    }
  }

  Future<void> markVersionDismissed(int versionCode) async {
    try {
      await _storage.write(key: dismissedVersionKey, value: versionCode.toString());
    } catch (e) {
      debugPrint('[AppUpdateService] Error saving dismissed version: $e');
    }
  }

  Future<void> clearDismissedVersion() async {
    try {
      await _storage.delete(key: dismissedVersionKey);
    } catch (_) {}
  }

  static Future<bool> openUpdateUrl(String url) async {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error opening update URL: $e');
    }
    return false;
  }
}
