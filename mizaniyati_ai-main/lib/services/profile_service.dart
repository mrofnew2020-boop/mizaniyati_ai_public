import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/db/database_helper.dart';
import '../models/user_profile.dart';

class ProfileService {
  final _db = DatabaseHelper.instance;

  Future<UserProfile?> getProfile() async {
    final map = await _db.getProfile();
    if (map == null) return null;
    return UserProfile.fromMap(map);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _db.upsertProfile(profile.toMap());
  }

  Future<String> persistProfileImage(String tempPath) async {
    final docs = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = p.join(docs.path, fileName);
    await File(tempPath).copy(dest);
    return dest;
  }
}
