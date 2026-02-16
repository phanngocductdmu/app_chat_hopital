import 'package:intl/intl.dart';

class UserInfo {
  final String? code;
  final int? roleId;
  final String? name;
  final String? firstname;
  final String? lastname;
  final String? intro;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? socialAvatar;
  final int? gender;
  final String? dob;
  final String? pob;
  final String? idNumber;
  final String? idDate;
  final String? idPlace;
  final String? addStreet;
  final String? addWard;
  final String? addDistrict;
  final String? province;
  final String? emailVerifiedAt;
  final String? faceId;
  final String? gCode;
  final String? zaloId;
  final String? zaloKey;
  final String? nksid;
  final String? vcard;
  final int? active;
  final String? activationToken;
  final dynamic point;
  final dynamic nikon;
  final dynamic kason;
  final String? smsToken;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic>? address;

  UserInfo({
    this.code,
    this.roleId,
    this.name,
    this.firstname,
    this.lastname,
    this.intro,
    this.email,
    this.phone,
    this.avatar,
    this.socialAvatar,
    this.gender,
    this.dob,
    this.pob,
    this.idNumber,
    this.idDate,
    this.idPlace,
    this.addStreet,
    this.addWard,
    this.addDistrict,
    this.province,
    this.emailVerifiedAt,
    this.faceId,
    this.gCode,
    this.zaloId,
    this.zaloKey,
    this.nksid,
    this.vcard,
    this.active,
    this.activationToken,
    this.point,
    this.nikon,
    this.kason,
    this.smsToken,
    this.createdAt,
    this.updatedAt,
    this.address,
  });

  String? _formatDate(String? rawDate) {
    if (rawDate == null) return null;
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  String? get formattedDob => _formatDate(dob);
  String? get formattedIdDate => _formatDate(idDate);
  String? get formattedEmailVerifiedAt => _formatDate(emailVerifiedAt);
  String? get formattedCreatedAt => _formatDate(createdAt);
  String? get formattedUpdatedAt => _formatDate(updatedAt);

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      code: json['code'],
      roleId: json['role_id'],
      name: json['name'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      intro: json['intro'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      socialAvatar: json['social_avatar'],
      gender: json['gender'],
      dob: json['dob'],
      pob: json['pob'],
      idNumber: json['id_number'],
      idDate: json['id_date'],
      idPlace: json['id_place'],
      addStreet: json['add_street'],
      addWard: json['add_ward'],
      addDistrict: json['add_district'],
      province: json['province']?.toString(),
      emailVerifiedAt: json['email_verified_at'],
      faceId: json['face_id'],
      gCode: json['g_code'],
      zaloId: json['zalo_id'],
      zaloKey: json['zalo_key'],
      nksid: json['nksid'],
      vcard: json['vcard'],
      active: json['active'],
      activationToken: json['activation_token'],
      point: json['point'],
      nikon: json['nikon'],
      kason: json['kason'],
      smsToken: json['sms_token'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      address: json['address'],
    );
  }
}
