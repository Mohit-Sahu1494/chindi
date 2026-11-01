import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_app/data/models/app_version_model.dart';

void main() {
  group('AppVersionModel & In-App Update Engine Tests', () {
    test('parses version json and correctly identifies update availability', () {
      final json = {
        'latestVersion': '1.0.1',
        'latestVersionCode': 2,
        'minRequiredVersionCode': 1,
        'updateUrl': 'https://example.com/update.apk',
        'title': 'Naya Update Uplabdh Hai! 🚀',
        'releaseNotes': 'Naye features shamil kiye gaye hain.',
        'forceUpdate': false,
      };

      final model = AppVersionModel.fromJson(json);

      expect(model.latestVersion, '1.0.1');
      expect(model.latestVersionCode, 2);
      expect(model.updateUrl, 'https://example.com/update.apk');
      expect(model.title, 'Naya Update Uplabdh Hai! 🚀');
      expect(model.releaseNotes, 'Naye features shamil kiye gaye hain.');
      expect(model.forceUpdate, false);

      // Current code is 1, so 2 > 1 -> update is available
      expect(model.isUpdateAvailable, true);
      expect(model.isMandatory, false);
    });

    test('correctly identifies mandatory force update', () {
      final json = {
        'latestVersion': '2.0.0',
        'latestVersionCode': 5,
        'minRequiredVersionCode': 3,
        'updateUrl': 'https://example.com/update-v2.apk',
        'title': 'Mandatory Security Update',
        'releaseNotes': 'Critical security patches.',
        'forceUpdate': true,
      };

      final model = AppVersionModel.fromJson(json);

      expect(model.isUpdateAvailable, true);
      // Both forceUpdate=true and minRequiredVersionCode > currentVersionCode(1)
      expect(model.isMandatory, true);
    });

    test('no update when latestVersionCode is equal to or lower than currentVersionCode', () {
      final json = {
        'latestVersion': '1.0.0',
        'latestVersionCode': 1,
        'minRequiredVersionCode': 1,
        'updateUrl': '',
        'title': 'Latest',
        'releaseNotes': 'No new updates',
        'forceUpdate': false,
      };

      final model = AppVersionModel.fromJson(json);

      expect(model.isUpdateAvailable, false);
      expect(model.isMandatory, false);
    });
  });
}
