import 'package:uuid/uuid.dart';

class UuidGen {
  UuidGen._();
  static const _uuid = Uuid();
  static String generate() => _uuid.v4();
}
