import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs) { _load(); }
  final SharedPreferences _prefs;
  bool _ready = false;
  String? _role;
  int _payDay = 1;
  String _userName = '';
  String _pin = '1234'; // الرقم السري الافتراضي

  bool get ready => _ready;
  String? get role => _role;
  bool get roleSelected => _role != null;
  bool get isManager => _role == AppConstants.roleManager;
  bool get isRecorder => _role == AppConstants.roleRecorder;
  int get payDay => _payDay;
  String get userName => _userName;
  String get pin => _pin;

  Future<void> _load() async {
    _role = _prefs.getString('role');
    _payDay = _prefs.getInt('pay_day') ?? 1;
    _userName = _prefs.getString('user_name') ?? '';
    _pin = _prefs.getString('pin') ?? '1234'; // تحميل الرقم السري
    _ready = true;
    notifyListeners();
  }

  Future<void> setRole(String role) async {
    _role = role;
    await _prefs.setString('role', role);
    notifyListeners();
  }

  Future<void> setPayDay(int day) async {
    _payDay = day.clamp(1, 28);
    await _prefs.setInt('pay_day', _payDay);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _prefs.setString('user_name', name);
    notifyListeners();
  }

  Future<void> setPin(String newPin) async {
    _pin = newPin;
    await _prefs.setString('pin', newPin);
    notifyListeners();
  }

  Future<void> resetRole() async {
    _role = null;
    await _prefs.remove('role');
    notifyListeners();
  }
}
