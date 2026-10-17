// Renders screenshots of the main screens (run by .github/workflows/screens.yml).
//   flutter test --update-goldens tool/screenshots/screenshot_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nima_kickboxing/club_info.dart';
import 'package:nima_kickboxing/data/app_store.dart';
import 'package:nima_kickboxing/main.dart';
import 'package:nima_kickboxing/moves/moves.dart';
import 'package:nima_kickboxing/ui/combo_detail_page.dart';
import 'package:nima_kickboxing/ui/contact_page.dart';
import 'package:nima_kickboxing/ui/move_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ByteData> _file(String path) async =>
    ByteData.view(Uint8List.fromList(await File(path).readAsBytes()).buffer);

Future<void> _loadFonts() async {
  final vz = FontLoader('Vazirmatn');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    vz.addFont(rootBundle.load('assets/fonts/Vazirmatn-$w.ttf'));
  }
  await vz.load();
  await (FontLoader('BebasNeue')
        ..addFont(rootBundle.load('assets/fonts/BebasNeue-Regular.ttf')))
      .load();
  final root = Platform.environment['FLUTTER_ROOT']!;
  await (FontLoader('MaterialIcons')
        ..addFont(_file('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')))
      .load();
}

void main() {
  late AppStore store;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore();
    await store.load();
    store.addPlan(DateTime.now().weekday, 'کمبو و کیسه', '5 راند × 3 دقیقه کار با کیسه');
    store.addAnnouncement('کلاس پنجشنبه ساعت 18 برگزار می‌شود.');
  });

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NimaApp(store: store));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(Scaffold).first);
      await precacheImage(const AssetImage(clubPhotoAsset), ctx);
    });
    await tester.pump(const Duration(milliseconds: 900));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 650));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> push(WidgetTester tester, Widget page) async {
    final ctx = tester.element(find.byType(NavigationBar));
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => page));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('screens', (tester) async {
    await boot(tester);
    await shot(tester, '01_home');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await shot(tester, '02_home_scrolled');
    await tab(tester, 'آموزش');
    await shot(tester, '03_techniques');
    await tab(tester, 'کمبو');
    await shot(tester, '04_combos');
    await tab(tester, 'تایمر');
    await shot(tester, '05_timer');
    await tab(tester, 'باشگاه');
    await shot(tester, '06_club');
    await push(tester, MoveDetailPage(move: moveById('rhigh')));
    await shot(tester, '07_move_detail');
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await shot(tester, '08_move_detail_scrolled');
    await push(tester, ComboDetailPage(moveIds: combos[7].moveIds, level: combos[7].level, note: combos[7].note));
    await tester.pump(const Duration(milliseconds: 1200));
    await shot(tester, '09_combo_detail');
    await push(tester, const ContactPage());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await shot(tester, '10_contact');
  });

  testWidgets('timer running', (tester) async {
    await boot(tester);
    await tab(tester, 'تایمر');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('شروع تمرین'));
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(const Duration(seconds: 3));
    await shot(tester, '11_timer_running');
    await tester.tap(find.text('پایان'));
    await tester.pump();
  });
}
