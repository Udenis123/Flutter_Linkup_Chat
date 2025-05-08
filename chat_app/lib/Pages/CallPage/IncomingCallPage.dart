import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/Controller/CallController.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class IncomingCallPage extends StatefulWidget {
  final Map<String, dynamic> callData;

  const IncomingCallPage({required this.callData});

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  Future<void> _playRingtone() async {
    await FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true,
      volume: 1.0,
      asAlarm: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();
    final callType = widget.callData['callType'] ?? 'voice';
    final callerName = widget.callData['callerName'] ?? 'Unknown';
    final callerPic = widget.callData['callerPic'];

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    'Incoming ${callType[0].toUpperCase() + callType.substring(1)} Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    callerName,
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                ],
              ),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: callerPic ?? AssetsImage.defaultImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget:
                        (context, url, error) => Image.asset(
                          AssetsImage.defaultImage,
                          fit: BoxFit.cover,
                        ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.call_end),
                    onPressed: () async {
                      await FlutterRingtonePlayer().stop();
                      await callController.declineCall();
                      Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
                    },
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.call),
                    onPressed: () async {
                      await FlutterRingtonePlayer().stop();
                      await callController.acceptCall();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
