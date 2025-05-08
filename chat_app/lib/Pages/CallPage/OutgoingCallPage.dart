import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/Controller/CallController.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/Images.dart';

class OutgoingCallPage extends StatelessWidget {
  final UserModel receiver;
  final String callType;

  const OutgoingCallPage({
    Key? key,
    required this.receiver,
    required this.callType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  'Calling...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  receiver.name ?? 'Unknown',
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
                  imageUrl: receiver.profileImage ?? AssetsImage.defaultImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget:
                      (context, url, error) =>
                          Icon(Icons.person, size: 80, color: Colors.white70),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.call_end),
                  onPressed: () async {
                    await callController.endCall();
                    Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
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
