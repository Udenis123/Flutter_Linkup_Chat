import 'package:chat_app/Model/UserModel.dart';

class GroupModel {
  String? id;
  String? name;
  String? description;
  String? profileUrl;
  List<UserModel> members; // Ensure members is never null
  String? createdAt;
  String? createdBy;
  String? status;
  String? lastmessage;
  String? lastMessageTime;
  String? lastMessageBy;
  int? unReadCount;
  String? timeStamp;
  Map<String, dynamic>? memberUnreadStatus;
  String? lastSenderId;

  GroupModel({
    this.id,
    this.name,
    this.description,
    this.profileUrl,
    List<UserModel>? members, // Default to an empty list
    this.createdAt,
    this.createdBy,
    this.status,
    this.lastmessage,
    this.lastMessageTime,
    this.lastMessageBy,
    this.unReadCount,
    this.timeStamp,
    this.memberUnreadStatus,
    this.lastSenderId,
  }) : members = members ?? []; // Initialize members to an empty list if null

  GroupModel.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      description = json['description'],
      profileUrl = json['profileUrl'],
      members =
          (json['members'] as List?)?.map((e) {
            return UserModel.fromJson(Map<String, dynamic>.from(e));
          }).toList() ??
          [], // Handle null or missing members field
      createdAt = json['createdAt'],
      createdBy = json['createdBy'],
      status = json['status'],
      lastmessage = json['lastmessage'],
      lastMessageTime = json['lastMessageTime'],
      lastMessageBy = json['lastMessageBy'],
      unReadCount = json['unReadCount'],
      timeStamp = json['timeStamp'],
      memberUnreadStatus =
          json['memberUnreadStatus'] != null
              ? Map<String, dynamic>.from(json['memberUnreadStatus'])
              : {},
      lastSenderId = json['lastSenderId'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['profileUrl'] = profileUrl;
    data['members'] = members.map((e) => e.toJson()).toList();
    data['createdAt'] = createdAt;
    data['createdBy'] = createdBy;
    data['status'] = status;
    data['lastmessage'] = lastmessage;
    data['lastMessageTime'] = lastMessageTime;
    data['lastMessageBy'] = lastMessageBy;
    data['unReadCount'] = unReadCount;
    data['timeStamp'] = timeStamp;
    data['memberUnreadStatus'] = memberUnreadStatus;
    data['lastSenderId'] = lastSenderId;
    return data;
  }
}
