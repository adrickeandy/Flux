class UserModel {
  final String uid;
  final String displayName;
  final String? photoURL;
  final String? email;
  final String? phoneNumber;
  final String? about;
  final bool isOnline;
  final int? lastSeen;

  UserModel({
    required this.uid,
    required this.displayName,
    this.photoURL,
    this.email,
    this.phoneNumber,
    this.about,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] ?? 'User',
      photoURL: map['photoURL'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      about: map['about'] ?? 'Hey I use FLUX',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'],
    );
  }
}