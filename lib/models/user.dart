class User {
  String? id;
  String? email;
  String? firstName;
  String? lastName;
  String? address;
  String? mobile;
  String? postcode;
  String? password;
  String? aboutus;
  DateTime? dateOfBirth;
  String? city;
  String? state;
  String? country;
  String? imageUrl;
  bool? status;
  // String? userMembershipId;
  DateTime? createdAt;
  DateTime? updatedAt;

  User({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.address,
    this.mobile,
    this.postcode,
    this.password,
    this.aboutus,
    this.dateOfBirth,
    this.city,
    this.state,
    this.country,
    this.imageUrl,
    this.status,
    //this.userMembershipId,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      email: data['email'],
      firstName: data['first_name'],
      lastName: data['last_name'],
      address: data['address'],
      mobile: data['mobile'],
      postcode: data['postcode'],
      password: data['password'],
      aboutus: data['aboutus'],
      dateOfBirth:
          data['date_of_birth'] != null
              ? DateTime.parse(data['date_of_birth'])
              : null,
      city: data['city'],
      state: data['state'],
      country: data['country'],
      imageUrl: data['profile_picture'],
      status: data['status'],
      //userMembershipId: data['user_membership_id'],
      createdAt:
          data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : null,
      updatedAt:
          data['updated_at'] != null
              ? DateTime.parse(data['updated_at'])
              : null,
    );
  }
}
















// import 'package:cloud_firestore/cloud_firestore.dart';

// class User {
//   String? id;
//   String? email;
//   String? firstName;
//   String? lastName;
//   String? address;
//   String? mobile;
//   String? postcode;
//   String? password;
//   String? aboutus;
//   DateTime? dateOfBirth;
//   String? city;
//   String? state;
//   String? country;
//   String? imageUrl;
//   String? userMembershipId;
//   DateTime? createdAt;
//   DateTime? updatedAt;

//   User({this.id,this.email,this.firstName,this.lastName,this.address,this.mobile,this.postcode,this.password,this.aboutus,this.dateOfBirth,this.city,this.state,this.country,this.imageUrl,this.userMembershipId,this.createdAt,this.updatedAt});

//   factory User.fromDocument(DocumentSnapshot snapshot) {
//     Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//     return User(
//       id: data['id'],
//       email: data['email'],
//       firstName: data['firstName'],
//       lastName: data['lastName'],
//       address: data['address'],
//       mobile: data['mobile'],
//       postcode: data['postcode'],
//       password: data['password'],
//       aboutus: data['aboutus'],
//       dateOfBirth: data['dateOfBirth']!=null ? (data['dateOfBirth'] as Timestamp).toDate() : null,
//       city: data['city'],
//       state: data['state'],
//       country: data['country'],
//       imageUrl: data['imageUrl'],
//       userMembershipId: data['userMembershipId'],
//       createdAt: (data['createdAt'] as Timestamp).toDate(),
//       updatedAt: (data['updatedAt'] as Timestamp).toDate(),
//     );
//   }

// }