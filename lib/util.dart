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

/// کلید = DateTime.weekday (دوشنبه ۱ ... یکشنبه ۷)
const faWeekdays = <int, String>{
  6: 'شنبه',
  7: 'یکشنبه',
  1: 'دوشنبه',
  2: 'سه‌شنبه',
  3: 'چهارشنبه',
  4: 'پنجشنبه',
  5: 'جمعه',
};

/// ترتیب هفته‌ی ایرانی، از شنبه تا جمعه
const weekOrder = [6, 7, 1, 2, 3, 4, 5];

String two(int n) => n.toString().padLeft(2, '0');

/// ارقام انگلیسی را به فارسی تبدیل می‌کند.
String toFa(Object value) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  return value
      .toString()
      .replaceAllMapped(RegExp(r'[0-9]'), (m) => fa[int.parse(m[0]!)]);
}

/// ارقام فارسی و عربی را به انگلیسی تبدیل می‌کند (برای خواندن ورودی کاربر).
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

/// عدد اعشاری بدون «.۰» اضافه: ۷۲ یا ۷۲.۵
String fmtNum(double v) =>
    toFa(v == v.roundToDouble() ? v.toInt().toString() : v.toString());

/// مبلغ با جداکننده‌ی هزارگان و ارقام فارسی
String money(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('٬');
    b.write(s[i]);
  }
  return toFa(v < 0 ? '-$b' : b.toString());
}

/// کلید روز میلادی برای ذخیره‌سازی: 2026-10-16
String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// تاریخ شمسی خوانا؛ مثل ۲۴ مهر ۱۴۰۵
String jalaliLabel(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${toFa(j.day)} ${faMonths[j.month - 1]} ${toFa(j.year)}';
}

/// کلید ماه شمسی؛ مثل 1405/07
String monthKey(DateTime d) {
  final j = Jalali.fromDateTime(d);
  return '${j.year}/${two(j.month)}';
}

String monthLabel(String key) {
  final p = key.split('/');
  final y = int.parse(p[0]);
  final m = int.parse(p[1]);
  return '${faMonths[m - 1]} ${toFa(y)}';
}

String shiftMonth(String key, int delta) {
  final p = key.split('/');
  final y = int.parse(p[0]);
  final m = int.parse(p[1]);
  final idx = y * 12 + (m - 1) + delta;
  return '${idx ~/ 12}/${two(idx % 12 + 1)}';
}
