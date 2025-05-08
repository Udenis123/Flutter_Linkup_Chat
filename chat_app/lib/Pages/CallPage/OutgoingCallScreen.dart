import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OutgoingCallScreen extends StatefulWidget {
  final String callId;
  final String receiverName;
  final String receiverPic;
  final String callType;

  const OutgoingCallScreen({
    Key? key,
    required this.callId,
    required this.receiverName,
    required this.receiverPic,
    required this.callType,
  }) : super(key: key);

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  late Stream<DocumentSnapshot> _callStream;

  @override
  void initState() {
    super.initState();
    _callStream =
        FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.callId)
            .snapshots();
  }

  Future<void> _endCall() async {
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': 'ended'});
      Get.back();
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _callStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final callStatus = snapshot.data!['status'];
                  if (callStatus == 'accepted') {
                    // Navigate to call screen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Get.offNamed(
                        '/call',
                        arguments: {
                          'callId': widget.callId,
                          'isCaller': true,
                          'callType': widget.callType,
                        },
                      );
                    });
                  } else if (callStatus == 'ended') {
                    // Close the screen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Get.back();
                    });
                  }
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Calling...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.receiverPic,
                              placeholder:
                                  (context, url) =>
                                      const CircularProgressIndicator(),
                              errorWidget:
                                  (context, url, error) =>
                                      const Icon(Icons.person),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.receiverName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    FloatingActionButton(
                      onPressed: _endCall,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
