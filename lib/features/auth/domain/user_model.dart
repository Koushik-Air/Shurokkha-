class UserModel {
  final String uid;
  final String email;
  final String phoneNumber;
  final String displayName;

  UserModel({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.displayName,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'phoneNumber': phoneNumber,
        'displayName': displayName,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        email: map['email'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        displayName: map['displayName'] ?? '',
      );
}
