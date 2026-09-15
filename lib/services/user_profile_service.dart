import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? name;
  final String? mobileNumber;
  final String? email;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    this.name,
    this.mobileNumber,
    this.email,
    this.photoUrl,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String?,
      mobileNumber: map['mobileNumber'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'photoUrl': photoUrl,
    };
  }
}

class UserProfileService {
  UserProfileService._internal();
  static final UserProfileService instance = UserProfileService._internal();

  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateName(String uid, String name) async {
    await _users.doc(uid).set({'name': name}, SetOptions(merge: true));
  }

  Future<void> updateMobileNumber(String uid, String mobileNumber) async {
    await _users
        .doc(uid)
        .set({'mobileNumber': mobileNumber}, SetOptions(merge: true));
  }

  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _users.doc(uid).set({'photoUrl': photoUrl}, SetOptions(merge: true));
  }
}
