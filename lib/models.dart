/// مدل‌های داده‌ی اپ. همه‌ی مدل‌ها به JSON تبدیل می‌شوند تا هم ذخیره‌ی محلی
/// و هم اتصال بعدی به بک‌اند (Firebase / Supabase / PocketBase) ساده باشد.

class Student {
  Student({
    required this.id,
    required this.name,
    this.phone = '',
    this.emergencyPhone = '',
    this.level = 0,
    this.weightKg,
    this.monthlyFee = 0,
    this.notes = '',
  });

  final String id;
  String name;
  String phone;
  String emergencyPhone;

  /// ۰ مبتدی، ۱ متوسط، ۲ حرفه‌ای
  int level;
  double? weightKg;

  /// شهریه‌ی ماهانه به تومان
  int monthlyFee;

  /// یادداشت خصوصی مربی
  String notes;

  static const levels = ['مبتدی', 'متوسط', 'حرفه‌ای'];

  String get levelLabel => levels[level.clamp(0, levels.length - 1).toInt()];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'emergencyPhone': emergencyPhone,
        'level': level,
        'weightKg': weightKg,
        'monthlyFee': monthlyFee,
        'notes': notes,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        emergencyPhone: (j['emergencyPhone'] as String?) ?? '',
        level: (j['level'] as num?)?.toInt() ?? 0,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        monthlyFee: (j['monthlyFee'] as num?)?.toInt() ?? 0,
        notes: (j['notes'] as String?) ?? '',
      );
}

class Payment {
  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.month,
    required this.dateIso,
  });

  final String id;
  final String studentId;

  /// مبلغ به تومان
  final int amount;

  /// ماه شمسی که این پرداخت برای آن است؛ مثل ۱۴۰۵/۰۷
  final String month;
  final String dateIso;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'amount': amount,
        'month': month,
        'dateIso': dateIso,
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        studentId: j['studentId'] as String,
        amount: (j['amount'] as num).toInt(),
        month: j['month'] as String,
        dateIso: j['dateIso'] as String,
      );
}

class PlanItem {
  PlanItem({
    required this.id,
    required this.weekday,
    required this.title,
    this.details = '',
  });

  final String id;

  /// مثل DateTime.weekday: دوشنبه ۱ ... یکشنبه ۷ (شنبه ۶)
  final int weekday;
  final String title;
  final String details;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekday': weekday,
        'title': title,
        'details': details,
      };

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        id: j['id'] as String,
        weekday: (j['weekday'] as num).toInt(),
        title: j['title'] as String,
        details: (j['details'] as String?) ?? '',
      );
}

class Announcement {
  Announcement({
    required this.id,
    required this.text,
    required this.createdAtIso,
  });

  final String id;
  final String text;
  final String createdAtIso;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAtIso': createdAtIso,
      };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as String,
        text: j['text'] as String,
        createdAtIso: j['createdAtIso'] as String,
      );
}
