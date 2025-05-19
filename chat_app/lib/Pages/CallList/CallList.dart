import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Controller/CallController.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallListPage extends StatefulWidget {
  const CallListPage({super.key});

  @override
  State<CallListPage> createState() => _CallListPageState();
}

class _CallListPageState extends State<CallListPage>
    with AutomaticKeepAliveClientMixin {
  final ProfileController profileController = Get.put(ProfileController());
  final CallController callController = Get.find<CallController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? callLogsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final user = _auth.currentUser;
    if (user != null) {
      callLogsStream =
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('callLogs')
              .orderBy('timestamp', descending: true)
              .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!authSnapshot.hasData || authSnapshot.data == null) {
            return Center(child: Text("Please login to view call logs"));
          }

          // User is authenticated, show call logs
          return StreamBuilder<QuerySnapshot>(
            stream: callLogsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error loading call logs"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No call logs yet",
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              final calls = snapshot.data!.docs;
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _initializeStream();
                  });
                },
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: calls.length,
                  itemBuilder: (context, index) {
                    final doc = calls[index];
                    final call = doc.data() as Map<String, dynamic>;
                    final isOutgoing =
                        call['callerUid'] == _auth.currentUser?.uid;
                    final isMissed =
                        call['status'] == 'missed' ||
                        (call['status'] == 'ended' &&
                            (call['accepted'] == false ||
                                call['accepted'] == null));
                    final callType = call['callType'] ?? 'voice';
                    final otherUserId =
                        isOutgoing ? call['receiverUid'] : call['callerUid'];
                    final otherUserName =
                        isOutgoing ? call['receiverName'] : call['callerName'];
                    final otherUserPic =
                        isOutgoing ? call['receiverPic'] : call['callerPic'];
                    final otherUserEmail =
                        isOutgoing
                            ? call['receiverEmail']
                            : call['callerEmail'];
                    final time =
                        call['timestamp'] != null
                            ? DateFormat(
                              'hh:mm a, MMM d',
                            ).format(DateTime.parse(call['timestamp']))
                            : '';

                    IconData icon;
                    Color iconColor;
                    if (isMissed) {
                      icon = Icons.call_missed;
                      iconColor = Colors.red;
                    } else if (isOutgoing) {
                      icon = Icons.call_made;
                      iconColor = Colors.green;
                    } else {
                      icon = Icons.call_received;
                      iconColor = Colors.blue;
                    }

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        color: Colors.redAccent,
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (direction) async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_auth.currentUser?.uid)
                            .collection('callLogs')
                            .doc(doc.id)
                            .delete();
                        Get.snackbar(
                          'Deleted',
                          'Call log deleted',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                otherUserPic != null && otherUserPic.isNotEmpty
                                    ? NetworkImage(otherUserPic)
                                    : null,
                            child:
                                (otherUserPic == null || otherUserPic.isEmpty)
                                    ? Icon(Icons.person, size: 28)
                                    : null,
                            radius: 26,
                          ),
                          title: Text(
                            otherUserName ?? 'Unknown',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(icon, color: iconColor, size: 18),
                              SizedBox(width: 4),
                              Text(
                                callType == 'video' ? 'Video' : 'Voice',
                                style: TextStyle(
                                  color:
                                      callType == 'video'
                                          ? Colors.purple
                                          : Colors.teal,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                time,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              callType == 'video' ? Icons.videocam : Icons.call,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Call Back'),
                                      content: Text(
                                        'Do you want to ${callType == 'video' ? 'video' : 'voice'} call $otherUserName?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Text('Call'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                final targetUser = UserModel(
                                  id: otherUserId,
                                  name: otherUserName,
                                  email: otherUserEmail,
                                  profileImage: otherUserPic,
                                );
                                await callController.startCall(
                                  targetUser,
                                  profileController.currentUser.value,
                                  callType: callType,
                                );
                              }
                            },
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Call Details'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Name: $otherUserName'),
                                        Text(
                                          'Type: ${callType == 'video' ? 'Video' : 'Voice'}',
                                        ),
                                        Text(
                                          'Direction: ${isOutgoing ? 'Outgoing' : 'Incoming'}',
                                        ),
                                        Text(
                                          'Status: ${call['status'] ?? 'Unknown'}',
                                        ),
                                        Text('Time: $time'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text('Close'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
