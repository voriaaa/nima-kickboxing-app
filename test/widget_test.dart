import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nima_kickboxing/moves/moves.dart';
import 'package:nima_kickboxing/moves/pose_data.g.dart';
import 'package:nima_kickboxing/util.dart';

void main() {
  test('toEn converts Persian and Arabic digits', () {
    expect(toEn('۱۲۳۴۵'), '12345');
    expect(toEn('١٢'), '12');
  });

  test('money uses English digits and commas', () {
    expect(money(1250000), '1,250,000');
    expect(money(0), '0');
  });

  test('parseInt reads Persian input with separators', () {
    expect(parseInt('۱٬۲۰۰٬۰۰۰'), 1200000);
    expect(parseInt('abc'), isNull);
  });

  test('shiftMonth crosses years', () {
    expect(shiftMonth('1405/12', 1), '1406/01');
    expect(shiftMonth('1405/01', -1), '1404/12');
  });

  test('every move has animation data', () {
    for (final m in moves) {
      expect(moveClips.containsKey(m.id), isTrue, reason: m.id);
    }
  });

  test('combos only use known moves', () {
    final ids = moves.map((m) => m.id).toSet();
    for (final c in combos) {
      for (final id in c.moveIds) {
        expect(ids.contains(id), isTrue, reason: '${c.id}: $id');
      }
    }
  });

  test('random combos are valid at every level', () {
    final r = Random(1);
    final ids = moves.map((m) => m.id).toSet();
    for (var level = 0; level < 3; level++) {
      for (var i = 0; i < 200; i++) {
        final c = randomCombo(r, level);
        expect(c.length, greaterThanOrEqualTo(2));
        expect(c.every(ids.contains), isTrue);
      }
    }
  });
}
