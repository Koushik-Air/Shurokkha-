class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? email;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.email,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phoneNumber': phoneNumber,
        'email': email,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) => EmergencyContact(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        relationship: map['relationship'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        email: map['email'],
      );
}
