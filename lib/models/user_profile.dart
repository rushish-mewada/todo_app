import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? phoneNumber;

  @HiveField(4)
  String? gender;

  @HiveField(5)
  String? role;

  @HiveField(6)
  String? remoteProfileUrl;

  @HiveField(7)
  String? localProfilePath;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.role,
    this.remoteProfileUrl,
    this.localProfilePath,
  });
}
