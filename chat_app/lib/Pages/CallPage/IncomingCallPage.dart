import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/Pages/CallPage/AudioCallPage.dart';
import 'package:chat_app/Pages/CallPage/VideoCallPage.dart';
import 'package:chat_app/Model/UserModel.dart';

class IncomingCallPage extends StatelessWidget {
  final Map<String, dynamic> callData;
  IncomingCallPage({required this.callData});

  @override
  Widget build(BuildContext context) {
    final callId = callData['id'];
    // Try both 'callType' and 'call_type' for robustness
    final callType = callData['callType'] ?? callData['call_type'] ?? 'voice';
    final callTypeText = callType == 'video' ? 'Video Call' : 'Voice Call';
    print('IncomingCallPage callType: $callType, callData: $callData');
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              callType == 'video' ? Icons.videocam : Icons.call,
              color: callType == 'video' ? Colors.blue : Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Incoming $callTypeText from ${callData['callerName']}',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.call, color: Colors.white),
                  label: Text('Accept', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("calls")
                        .doc(callId)
                        .update({'status': 'accepted'});
                    // Navigate to correct call page
                    final target = UserModel(
                      id: callData['callerUid'],
                      name: callData['callerName'],
                      email: callData['callerEmail'],
                      profileImage: callData['callerPic'],
                    );
                    print('Navigating to call room, callType: $callType');
                    if (callType == 'video') {
                      Get.off(() => VideoCallPage(target: target));
                    } else {
                      Get.off(() => AudioCallPage(target: target));
                    }
                  },
                ),
                SizedBox(width: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.call_end, color: Colors.white),
                  label: Text('Decline', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("calls")
                        .doc(callId)
                        .update({'status': 'ended'});
                    Get.back();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
