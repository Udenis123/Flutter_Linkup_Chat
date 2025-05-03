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
    return data;
  }
}
