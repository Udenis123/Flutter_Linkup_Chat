import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final lastChat;
  final String lastTime;
  final String userId;
  final int? unreadCount;
  const ChatTile({
    super.key,
    required this.lastChat,
    required this.lastTime,
    required this.imageUrl,
    required this.name,
    required this.userId,
    this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

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
                        color: isOnline ? Colors.green : Colors.green,
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
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          (unreadCount != null && unreadCount! > 0)
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 7),
                  Container(
                    width: 200,
                    child: Text(
                      lastChat,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight:
                            (unreadCount != null && unreadCount! > 0)
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color:
                            (unreadCount != null && unreadCount! > 0)
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Time text
              Text(
                lastTime,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),

              // Unread message count badge
              if (unreadCount != null && unreadCount! > 0)
                Container(
                  margin: EdgeInsets.only(top: 5),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
