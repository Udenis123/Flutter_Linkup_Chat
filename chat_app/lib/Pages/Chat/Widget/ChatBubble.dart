import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Chatbubble extends StatelessWidget {
  final String message;
  final bool isComming;
  final String time;
  final String status;
  final String imageUrl;

  const Chatbubble({
    super.key,
    required this.message,
    required this.isComming,
    required this.time,
    required this.status,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    void _showImageDialog(BuildContext context, String url) {
      showDialog(
        context: context,
        builder:
            (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isComming ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: imageUrl == "" ? EdgeInsets.all(8) : EdgeInsets.all(3),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width / 1.3,
            ),
            decoration: BoxDecoration(
              color:
                  isComming
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Color(const Color.fromARGB(255, 9, 89, 155).value),
              borderRadius:
                  isComming
                      ? BorderRadius.only(
                        topLeft:
                            imageUrl == ""
                                ? Radius.circular(20)
                                : Radius.circular(5),
                        topRight:
                            imageUrl == ""
                                ? Radius.circular(20)
                                : Radius.circular(5),
                        bottomLeft: Radius.circular(0),
                        bottomRight:
                            imageUrl == ""
                                ? Radius.circular(20)
                                : Radius.circular(5),
                      )
                      : BorderRadius.only(
                        topLeft:
                            imageUrl == ""
                                ? Radius.circular(20)
                                : Radius.circular(5),
                        topRight:
                            imageUrl == ""
                                ? Radius.circular(20)
                                : Radius.circular(5),
                        bottomLeft:
                            imageUrl == ""
                                ? Radius.circular(20)
                                : Radius.circular(5),
                        bottomRight: Radius.circular(0),
                      ),
            ),
            child:
                imageUrl == ""
                    ? Text(
                      message,
                      style: TextStyle(fontSize: 17, fontFamily: "Poppins"),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: GestureDetector(
                            onTap: () => _showImageDialog(context, imageUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        CircularProgressIndicator(),
                                errorWidget:
                                    (context, url, error) => Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                        message == "" ? Container() : SizedBox(),
                        message == "" ? Container() : Text(message),
                      ],
                    ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment:
                isComming ? MainAxisAlignment.start : MainAxisAlignment.end,

            children: [
              isComming
                  ? Text(time, style: Theme.of(context).textTheme.labelMedium)
                  : Row(
                    children: [
                      Text(
                        time,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.done_all, color: Colors.grey, size: 15),
                    ],
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
