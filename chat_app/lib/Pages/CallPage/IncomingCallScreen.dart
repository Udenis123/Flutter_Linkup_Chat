import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerName;
  final String callerPic;
  final String callType;

  const IncomingCallScreen({
    Key? key,
    required this.callId,
    required this.callerName,
    required this.callerPic,
    required this.callType,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  Future<void> _handleAcceptCall() async {
    try {
      await FlutterRingtonePlayer().stop();
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': 'accepted'});

      Get.offNamed(
        '/call',
        arguments: {
          'callId': widget.callId,
          'isCaller': false,
          'callType': widget.callType,
        },
      );
    } catch (e) {
      print('Error accepting call: $e');
    }
  }

  Future<void> _handleRejectCall() async {
    try {
      await FlutterRingtonePlayer().stop();
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'status': 'ended'});
      Get.back();
    } catch (e) {
      print('Error rejecting call: $e');
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Incoming ${widget.callType} Call',
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
                          imageUrl: widget.callerPic,
                          placeholder:
                              (context, url) =>
                                  const CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.person),
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      onPressed: _handleRejectCall,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end),
                    ),
                    FloatingActionButton(
                      onPressed: _handleAcceptCall,
                      backgroundColor: Colors.green,
                      child: Icon(
                        widget.callType == 'video'
                            ? Icons.videocam
                            : Icons.call,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
