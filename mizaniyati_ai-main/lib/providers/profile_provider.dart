import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final _service = ProfileService();
  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _profile = await _service.getProfile();
    _loading = false;
    notifyListeners();
  }

  Future<UserProfile?> getProfile() async {
    if (_profile != null) return _profile;
    await load();
    return _profile;
  }

  Future<void> save(UserProfile p) async {
    await _service.saveProfile(p);
    _profile = p;
    notifyListeners();
  }

  Future<String> persistImage(String tempPath) =>
      _service.persistProfileImage(tempPath);
}
