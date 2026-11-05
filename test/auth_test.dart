import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semis_flutter/models/auth_user.dart';
import 'package:semis_flutter/screens/login_screen.dart';
import 'package:semis_flutter/services/auth_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('US-01: AuthUser Model Tests', () {
    test('AuthUser serialization and deserialization works correctly', () {
      final user = AuthUser(
        id: 'user-123',
        name: 'Pak Budi Peternak',
        email: 'budi@gmail.com',
        photoUrl: 'https://example.com/photo.jpg',
        accessToken: 'access-token-xyz',
        idToken: 'id-token-xyz',
        loggedInAt: DateTime(2026, 10, 20, 10, 0),
        isOffline: false,
        hasDriveScope: true,
      );

      final jsonStr = user.toJson();
      final fromJson = AuthUser.fromJson(jsonStr);

      expect(fromJson.id, 'user-123');
      expect(fromJson.name, 'Pak Budi Peternak');
      expect(fromJson.email, 'budi@gmail.com');
      expect(fromJson.photoUrl, 'https://example.com/photo.jpg');
      expect(fromJson.accessToken, 'access-token-xyz');
      expect(fromJson.hasDriveScope, true);
      expect(fromJson.isOffline, false);
    });

    test('AuthUser copyWith preserves and updates values correctly', () {
      final user = AuthUser(
        id: 'user-1',
        name: 'Peternak',
        email: 'peternak@gmail.com',
        loggedInAt: DateTime.now(),
        isOffline: false,
        hasDriveScope: true,
      );

      final offlineUser = user.copyWith(isOffline: true);
      expect(offlineUser.isOffline, true);
      expect(offlineUser.email, 'peternak@gmail.com');
      expect(offlineUser.hasDriveScope, true);
    });
  });

  group('US-01: AuthService Logic & Acceptance Criteria Tests', () {
    test('AC 3: Scope Denial returns AuthStatus.permissionDenied with clear explanation',
        () async {
      final result = await AuthService.instance.signInWithGoogle(
        simulateScopeDenial: true,
      );

      expect(result.status, AuthStatus.permissionDenied);
      expect(
        result.message.contains('Izin akses Google Drive ditolak'),
        true,
      );
      expect(
        result.message.contains('izin Google Drive untuk menyimpan'),
        true,
      );
    });

    test('AC 2: Offline Authentication without session returns offlineNoSession',
        () async {
      await AuthService.instance.clearSession();
      final result = await AuthService.instance.signInOffline();

      expect(result.status, AuthStatus.offlineNoSession);
      expect(result.isSuccess, false);
    });

    test('AC 2: Offline Authentication with valid session succeeds', () async {
      final user = AuthUser(
        id: 'user-offline-1',
        name: 'Pak Ahmad',
        email: 'ahmad@peternakan.id',
        loggedInAt: DateTime.now(),
        isOffline: false,
        hasDriveScope: true,
      );

      await AuthService.instance.saveSession(user);
      final result = await AuthService.instance.signInOffline();

      expect(result.status, AuthStatus.offlineSuccess);
      expect(result.isSuccess, true);
      expect(result.user?.isOffline, true);
      expect(result.user?.name, 'Pak Ahmad');
    });
  });

  group('US-01: LoginScreen Widget Tests', () {
    testWidgets('AC 1 & UI: Sign in with Google button is displayed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(onLogin: () {}),
        ),
      );
      await tester.pump();

      // Verify branding and title
      expect(find.text('SEMIS'), findsOneWidget);
      expect(find.text('Sistem Informasi Silsilah & Pemuliaan Domba'),
          findsOneWidget);

      // Verify Google Sign-In Button
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsWidgets);
    });
  });
}

