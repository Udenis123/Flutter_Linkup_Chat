import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final lastChat;
  final String lastTime;
  final String userId;
  const ChatTile({
    super.key,
    required this.lastChat,
    required this.lastTime,
    required this.imageUrl,
    required this.name,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                builder: (context, snapshot) {
                  bool isOnline = false;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    isOnline = data['status'] == 'Online';
                  }
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isOnline ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: 7),
                  Container(
                    width: 200,
                    child: Text(
                      lastChat,
                      style: Theme.of(context).textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Limit time text width
          Text(
            lastTime,
            style: Theme.of(context).textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
