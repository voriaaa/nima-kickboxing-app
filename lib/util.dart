import 'package:shamsi_date/shamsi_date.dart';

const faMonths = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

/// Key = DateTime.weekday (Monday 1 ... Sunday 7)
const faWeekdays = <int, String>{
  6: 'شنبه',
  7: 'یکشنبه',
  1: 'دوشنبه',
  2: 'سه‌شنبه',
  3: 'چهارشنبه',
  4: 'پنجشنبه',
  5: 'جمعه',
};

/// Iranian week order, Saturday to Friday
const weekOrder = [6, 7, 1, 2, 3, 4, 5];

String two(int n) => n.toString().padLeft(2, '0');

/// Converts Persian and Arabic digits typed by the user to English digits.
String toEn(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = fa.indexOf(ch);
    final j = ar.indexOf(ch);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else if (ch == '٫') {
      b.write('.');
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

int? parseInt(String text) {
  final cleaned = toEn(text).replaceAll(RegExp(r'[,٬\s]'), '');
  return int.tryParse(cleaned);
}

double? parseDouble(String text) {
  final cleaned = toEn(text).replaceAll(RegExp(r'[,٬\s]'), '');
  return double.tryParse(cleaned);
}

/// 72 or 72.5 (no trailing .0)
String fmtNum(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Amount with thousands separators: 1,250,000
String money(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return v < 0 ? '-$b' : b.toString();
}

/// Storage key for a day: 2026-10-16
String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// Readable Jalali date, e.g. 24 مهر 1405
String jalaliLabel(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.day} ${faMonths[j.month - 1]} ${j.year}';
}

/// Jalali month key, e.g. 1405/07
String monthKey(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}/${two(j.month)}';
}

String monthLabel(String key) {
  final p = key.split('/');
  final y = int.parse(p[0]);
  final m = int.parse(p[1]);
  return '${faMonths[m - 1]} $y';
}

String shiftMonth(String key, int delta) {
  final p = key.split('/');
  final y = int.parse(p[0]);
  final m = int.parse(p[1]);
  final idx = y * 12 + (m - 1) + delta;
  return '${idx ~/ 12}/${two(idx % 12 + 1)}';
}

/// mm:ss
String mmss(int totalSeconds) =>
    '${two(totalSeconds ~/ 60)}:${two(totalSeconds % 60)}';
