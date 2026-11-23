import 'package:firearms_catalog/apk_filename.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds Ordnance-vX.Y.Z.apk when the server name is a scaffold name', () {
    expect(
      ordnanceApkFileName(
        version: '3.0.1',
        contentDisposition: 'attachment; filename="app-release.apk"',
      ),
      'Ordnance-v3.0.1.apk',
    );
    expect(
      ordnanceApkFileName(
        version: '3.0.1',
        contentDisposition: 'attachment; filename="firearms_catalog.apk"',
      ),
      'Ordnance-v3.0.1.apk',
    );
  });

  test('keeps a Content-Disposition name that is already Ordnance-v*.apk', () {
    expect(
      ordnanceApkFileName(
        version: '9.9.9',
        contentDisposition:
            "attachment; filename*=UTF-8''Ordnance-v3.0.1.apk",
      ),
      'Ordnance-v3.0.1.apk',
    );
  });

  test('rejects the old arm64 suffix and debug names from the header', () {
    expect(
      ordnanceApkFileName(
        version: '3.0.1',
        contentDisposition: 'attachment; filename="Ordnance-v3.0.1-arm64.apk"',
      ),
      'Ordnance-v3.0.1.apk',
    );
  });
}
