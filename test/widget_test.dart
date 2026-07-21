import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:foodeez_delivery/main.dart';
import 'package:foodeez_delivery/data/mock_data.dart';
import 'package:foodeez_delivery/models/app_models.dart';
import 'package:foodeez_delivery/controllers/app_controller.dart';

/// Pumps the app with an explicit [ProviderContainer] (instead of the plain
/// `ProviderScope` used in `main.dart`) so tests can read/drive the
/// [AppState] controller directly via `container.read(appControllerProvider)`
/// — the Riverpod equivalent of the old `tester.element(...).read<AppState>()`
/// Provider-package pattern.
Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const FoodeezRiderApp()));
  await tester.pump();
  return container;
}

void main() {
  testWidgets('App launches to the login screen', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Log in & go online'), findsOneWidget);
  });

  testWidgets('Map hero exposes full-bleed controls for a delivery-style dashboard', (WidgetTester tester) async {
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.zoomControlsEnabled, isTrue);
    expect(map.mapToolbarEnabled, isFalse);
    expect(map.myLocationButtonEnabled, isTrue);
    expect(map.compassEnabled, isTrue);
    expect(map.initialCameraPosition.zoom, greaterThanOrEqualTo(16));
  });

  testWidgets('Logging in navigates to Home', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Log in & go online'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("You're online"), findsOneWidget);
  });

  testWidgets('Every screen renders without layout exceptions', (WidgetTester tester) async {
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();

    const screens = ['home', 'history', 'earnings', 'profile'];
    for (final screen in screens) {
      app.tab(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Exception while rendering "$screen"');
    }

    for (final screen in ['ratings', 'help', 'signup']) {
      app.go(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'Exception while rendering "$screen"');
      app.back();
      await tester.pump();
    }
  });

  testWidgets('Online hero card fills the full width online and offline', (WidgetTester tester) async {
    // Regression test: the hero Container sat directly in a Column with
    // crossAxisAlignment.start, so it shrank to its content's intrinsic width
    // instead of the full card width — most visible in the online state,
    // whose centered Column content is narrower than the offline Row.
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();

    final screenWidth = tester.getSize(find.byType(MaterialApp)).width;

    expect(app.online, isTrue);
    final onlineWidth = tester.getSize(find.text("You're online")).width;
    // The card itself (not just the text) should span (near) the full screen
    // width minus the 20px side padding on each side.
    final onlineCardRect = tester.getRect(find.text("You're online"));
    expect(onlineCardRect.width, lessThan(screenWidth)); // sanity: text itself is narrower than the screen
    expect(onlineWidth, greaterThan(0));

    app.toggleOnline();
    await tester.pump();
    expect(app.online, isFalse);
    expect(find.text("You're offline"), findsOneWidget);

    // Compare the actual hero container widths in both states via the
    // GestureDetector that wraps the toggle — it should be identical
    // (full available width) regardless of online/offline content.
    app.toggleOnline();
    await tester.pump();
    final onlineHeroWidth = tester.getSize(find.ancestor(of: find.text("You're online"), matching: find.byType(SizedBox)).first).width;
    app.toggleOnline();
    await tester.pump();
    final offlineHeroWidth = tester.getSize(find.ancestor(of: find.text("You're offline"), matching: find.byType(SizedBox)).first).width;
    expect(onlineHeroWidth, equals(offlineHeroWidth));
    expect(onlineHeroWidth, greaterThan(screenWidth * 0.8)); // should span (almost) the full screen, not half
  });

  testWidgets('Streak bonus card only shows when fleet ops activates it', (WidgetTester tester) async {
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();

    expect(app.incentiveOffer, isNotNull, reason: 'demo data ships with an active campaign so the card is visible by default');
    expect(find.text('Trip streak bonus'), findsOneWidget);
    expect(find.text('Recent trips'), findsOneWidget);

    app.setIncentiveOffer(null);
    await tester.pump();
    expect(find.text('Trip streak bonus'), findsNothing);
    expect(find.text('Recent trips'), findsOneWidget); // still shown, just moves up
  });

  testWidgets('Full live-delivery flow: accept, pickup OTP, dropoff OTP+COD, complete', (WidgetTester tester) async {
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();

    app.openAlert();
    await tester.pump();
    expect(app.alertOpen, isTrue);

    app.acceptAlert();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.screen, 'trip');
    expect(app.stage, DeliveryStage.toPickup);
    expect(tester.takeException(), isNull);

    // Nothing to gate while still en route to the restaurant.
    expect(app.actionReady, isTrue);
    app.nextStage(); // to_pickup -> at_pickup (the map->arrived transition is a UI toggle, not gated)
    await tester.pump();
    expect(app.stage, DeliveryStage.atPickup);
    expect(app.actionReady, isFalse);

    app.setOtp('1234');
    await tester.pump();
    expect(app.otpDone, isTrue);
    expect(app.actionReady, isTrue);

    app.nextStage(); // at_pickup -> to_drop
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.stage, DeliveryStage.toDrop);
    expect(tester.takeException(), isNull);

    app.nextStage(); // to_drop -> at_drop
    await tester.pump();
    expect(app.stage, DeliveryStage.atDrop);
    // COD order: not ready until OTP entered AND cash collected.
    expect(app.actionReady, isFalse);
    app.setOtp('5678');
    expect(app.actionReady, isFalse);
    app.toggleCod();
    await tester.pump();
    expect(app.actionReady, isTrue);

    app.nextStage(); // at_drop -> tripdone
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.screen, 'tripdone');
    expect(tester.takeException(), isNull);
  });

  testWidgets('New signups land on document verification and stay gated until admin approves', (WidgetTester tester) async {
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    app.startNewApplication();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.screen, 'profile');
    expect(app.accountStatus, AccountStatus.pendingReview);
    expect(app.online, isFalse);

    // Cannot go online while pending review.
    app.toggleOnline();
    expect(app.online, isFalse);

    // Trying to navigate elsewhere is a no-op visually: the shell forces
    // Profile (where document verification lives) back onto screen.
    app.tab('home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.text("You're online"), findsNothing);
    expect(find.text("You're offline"), findsNothing);

    for (final doc in verifiableDocuments) {
      app.uploadDocument(doc.id);
      if (doc.requiresNumber) {
        app.setDocumentNumber(doc.id, '1234567890');
        app.verifyDocument(doc.id);
        expect(app.documentStatus[doc.id], DocumentStatus.pending);
      }
    }
    await tester.pump(const Duration(milliseconds: 1500));
    expect(app.allDocumentsVerified, isTrue);

    // Documents verified, but still needs admin approval to activate.
    expect(app.accountStatus, AccountStatus.pendingReview);
    app.simulateAdminApproval();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.accountStatus, AccountStatus.active);

    app.tab('home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("You're offline"), findsOneWidget);

    app.toggleOnline();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(app.online, isTrue);
  });

  testWidgets('Back buttons on pushed sub-screens hug the top', (WidgetTester tester) async {
    final container = await pumpApp(tester);
    final app = container.read(appControllerProvider);
    app.tab('home');
    await tester.pump();

    for (final screen in ['ratings', 'help']) {
      app.go(screen);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final rect = tester.getRect(find.byIcon(Icons.arrow_back_ios_new).first);
      expect(rect.top, lessThan(60), reason: 'Back button on "$screen" is too far from the top (top=${rect.top})');
      app.back();
      await tester.pump();
    }
  });
}
