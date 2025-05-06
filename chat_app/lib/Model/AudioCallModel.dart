class AudioCallModel {
  String? id;
  String? callerName;
  String? callerPic;
  String? callerUid;
  String? callerEmail;
  String? receiverName;
  String? receiverPic;
  String? receiverUid;
  String? receiverEmail;
  String? status;
  String? callType;
  List<String>? participants;
  DateTime? timestamp;

  AudioCallModel({
    this.id,
    this.callerName,
    this.callerPic,
    this.callerUid,
    this.callerEmail,
    this.receiverName,
    this.receiverPic,
    this.receiverUid,
    this.receiverEmail,
    this.status,
    this.callType,
    this.participants,
    this.timestamp,
  });

  AudioCallModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    callerName = json['callerName'];
    callerPic = json['callerPic'];
    callerUid = json['callerUid'];
    callerEmail = json['callerEmail'];
    receiverName = json['receiverName'];
    receiverPic = json['receiverPic'];
    receiverUid = json['receiverUid'];
    receiverEmail = json['receiverEmail'];
    status = json['status'];
    callType = json['callType'];
    participants =
        json['participants'] != null
            ? List<String>.from(json['participants'])
            : null;
    if (json['timestamp'] != null) {
      if (json['timestamp'] is String) {
        timestamp = DateTime.tryParse(json['timestamp']);
      } else if (json['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
      } else if (json['timestamp'] is DateTime) {
        timestamp = json['timestamp'];
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['callerName'] = callerName;
    data['callerPic'] = callerPic;
    data['callerUid'] = callerUid;
    data['callerEmail'] = callerEmail;
    data['receiverName'] = receiverName;
    data['receiverPic'] = receiverPic;
    data['receiverUid'] = receiverUid;
    data['receiverEmail'] = receiverEmail;
    data['status'] = status;
    data['callType'] = callType;
    if (participants != null) {
      data['participants'] = participants;
    }
    if (timestamp != null) {
      data['timestamp'] = timestamp!.toIso8601String();
    }
    return data;
  }
}
