import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../util.dart';

/// نگهدارنده‌ی همه‌ی داده‌های اپ.
///
/// نسخه‌ی اول: ذخیره‌ی محلی روی همین گوشی (SharedPreferences).
/// برای همگام‌سازی بین گوشی مربی و شاگردها، همین کلاس را با یک بک‌اند
/// (Firebase / Supabase / PocketBase) جایگزین می‌کنیم؛ صفحه‌ها فقط با
/// همین API کار می‌کنند و عوض نمی‌شوند.
class AppStore extends ChangeNotifier {
  static const _dataKey = 'nima_data_v1';
  static const _pinKey = 'nima_coach_pin';

  /// Null when storage is unavailable; the app then works in memory only.
  SharedPreferences? _prefs;

  /// False if the phone's storage could not be opened.
  bool storageOk = true;
  int _idCounter = 0;

  final List<Student> students = [];

  /// کلید روز (2026-10-16) به مجموعه‌ی شناسه‌ی شاگردهای حاضر
  final Map<String, Set<String>> attendance = {};
  final List<Payment> payments = [];
  final List<PlanItem> plans = [];
  final List<Announcement> announcements = [];

  String? coachPin;

  /// Coach panel is unlocked for this app session only.
  bool coachUnlocked = false;

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Never block startup on storage.
      debugPrint('storage unavailable: $e');
      storageOk = false;
      return;
    }
    final prefs = _prefs!;
    coachPin = prefs.getString(_pinKey);

    final raw = prefs.getString(_dataKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      students.addAll((j['students'] as List? ?? [])
          .map((e) => Student.fromJson(e as Map<String, dynamic>)));
      payments.addAll((j['payments'] as List? ?? [])
          .map((e) => Payment.fromJson(e as Map<String, dynamic>)));
      plans.addAll((j['plans'] as List? ?? [])
          .map((e) => PlanItem.fromJson(e as Map<String, dynamic>)));
      announcements.addAll((j['announcements'] as List? ?? [])
          .map((e) => Announcement.fromJson(e as Map<String, dynamic>)));
      final att = (j['attendance'] as Map<String, dynamic>?) ?? {};
      att.forEach((k, v) {
        attendance[k] = (v as List).cast<String>().toSet();
      });
    } catch (_) {
      // داده خراب بود: نسخه‌ی خام را نگه می‌داریم تا با ذخیره‌ی بعدی از بین نرود.
      await prefs.setString('${_dataKey}_corrupt', raw);
      students.clear();
      attendance.clear();
      payments.clear();
      plans.clear();
      announcements.clear();
    }
  }

  Future<void> _save() async {
    final data = {
      'students': students.map((e) => e.toJson()).toList(),
      'attendance': attendance.map((k, v) => MapEntry(k, v.toList())),
      'payments': payments.map((e) => e.toJson()).toList(),
      'plans': plans.map((e) => e.toJson()).toList(),
      'announcements': announcements.map((e) => e.toJson()).toList(),
    };
    try {
      await _prefs?.setString(_dataKey, jsonEncode(data));
    } catch (e) {
      debugPrint('save failed: $e');
    }
  }

  void _commit() {
    notifyListeners();
    unawaited(_save());
  }

  // ---------- ورود و خروج ----------

  bool checkPin(String pin) => coachPin != null && coachPin == pin;

  Future<void> setCoachPin(String pin) async {
    coachPin = pin;
    try {
      await _prefs?.setString(_pinKey, pin);
    } catch (e) {
      debugPrint('save pin failed: $e');
    }
  }

  void unlockCoach() {
    coachUnlocked = true;
    notifyListeners();
  }

  void lockCoach() {
    coachUnlocked = false;
    notifyListeners();
  }

  // ---------- شاگردها ----------

  Student? studentById(String? id) {
    if (id == null) return null;
    for (final s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  void addStudent(Student s) {
    students.add(s);
    _commit();
  }

  /// بعد از تغییر فیلدهای یک شاگرد صدا زده می‌شود.
  void updateStudent(Student s) => _commit();

  void deleteStudent(String id) {
    students.removeWhere((s) => s.id == id);
    payments.removeWhere((p) => p.studentId == id);
    for (final ids in attendance.values) {
      ids.remove(id);
    }
    _commit();
  }

  // ---------- حضور و غیاب ----------

  bool isPresent(String dayKey, String studentId) =>
      attendance[dayKey]?.contains(studentId) ?? false;

  void toggleAttendance(String dayKey, String studentId) {
    final set = attendance.putIfAbsent(dayKey, () => <String>{});
    if (!set.remove(studentId)) set.add(studentId);
    if (set.isEmpty) attendance.remove(dayKey);
    _commit();
  }

  /// روزهایی که شاگرد حاضر بوده، از جدید به قدیم
  List<String> attendedDays(String studentId) {
    final days = attendance.entries
        .where((e) => e.value.contains(studentId))
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return days;
  }

  int presentCountInMonth(String studentId, String month) {
    var n = 0;
    for (final day in attendedDays(studentId)) {
      if (monthKey(DateTime.parse(day)) == month) n++;
    }
    return n;
  }

  // ---------- شهریه ----------

  int paidFor(String studentId, String month) => payments
      .where((p) => p.studentId == studentId && p.month == month)
      .fold(0, (sum, p) => sum + p.amount);

  List<Payment> paymentsFor(String studentId, String month) => payments
      .where((p) => p.studentId == studentId && p.month == month)
      .toList()
    ..sort((a, b) => b.dateIso.compareTo(a.dateIso));

  void addPayment(String studentId, int amount, String month) {
    payments.add(Payment(
      id: newId(),
      studentId: studentId,
      amount: amount,
      month: month,
      dateIso: DateTime.now().toIso8601String(),
    ));
    _commit();
  }

  void deletePayment(String id) {
    payments.removeWhere((p) => p.id == id);
    _commit();
  }

  // ---------- برنامه‌ی تمرین ----------

  void addPlan(int weekday, String title, String details) {
    plans.add(PlanItem(
      id: newId(),
      weekday: weekday,
      title: title,
      details: details,
    ));
    _commit();
  }

  void deletePlan(String id) {
    plans.removeWhere((p) => p.id == id);
    _commit();
  }

  // ---------- اطلاعیه ----------

  void addAnnouncement(String text) {
    announcements.add(Announcement(
      id: newId(),
      text: text,
      createdAtIso: DateTime.now().toIso8601String(),
    ));
    _commit();
  }

  void deleteAnnouncement(String id) {
    announcements.removeWhere((a) => a.id == id);
    _commit();
  }
}

/// دسترسی به AppStore از هر جای درخت ویجت‌ها.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({
    super.key,
    required AppStore store,
    required super.child,
  }) : super(notifier: store);

  /// داخل build استفاده شود؛ با تغییر داده‌ها صفحه دوباره ساخته می‌شود.
  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope پیدا نشد');
    return scope!.notifier!;
  }

  /// داخل دکمه‌ها و کارهای غیر build استفاده شود.
  static AppStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope پیدا نشد');
    return scope!.notifier!;
  }
}
