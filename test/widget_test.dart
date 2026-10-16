import 'package:flutter_test/flutter_test.dart';
import 'package:nima_kickboxing/util.dart';

void main() {
  test('toFa ارقام را فارسی می‌کند', () {
    expect(toFa(1405), '۱۴۰۵');
  });

  test('toEn ارقام فارسی و عربی را انگلیسی می‌کند', () {
    expect(toEn('۱۲۳۴۵'), '12345');
    expect(toEn('١٢'), '12');
  });

  test('money هزارگان را جدا می‌کند', () {
    expect(money(1250000), '۱٬۲۵۰٬۰۰۰');
    expect(money(0), '۰');
  });

  test('parseInt ورودی فارسی با جداکننده را می‌خواند', () {
    expect(parseInt('۱٬۲۰۰٬۰۰۰'), 1200000);
    expect(parseInt('abc'), isNull);
  });

  test('shiftMonth بین سال‌ها درست جابه‌جا می‌شود', () {
    expect(shiftMonth('1405/12', 1), '1406/01');
    expect(shiftMonth('1405/01', -1), '1404/12');
  });
}
