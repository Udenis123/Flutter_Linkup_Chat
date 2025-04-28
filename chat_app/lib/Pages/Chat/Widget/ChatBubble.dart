import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Widget/VideoPreviewWidget.dart';
import 'package:flutter/material.dart';

class Chatbubble extends StatelessWidget {
  final String message;
  final bool isComming;
  final String time;
  final String status;
  final String imageUrl;
  final String videoUrl;

  const Chatbubble({
    super.key,
    required this.message,
    required this.isComming,
    required this.time,
    required this.status,
    required this.imageUrl,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    void _showMediaDialog(BuildContext context, String url, bool isVideo) {
      showDialog(
        context: context,
        useSafeArea: false, // Allow content to extend into safe area
        barrierColor: Colors.black, // Full black background
        builder:
            (ctx) => Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // Main content
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child:
                          isVideo
                              ? VideoPlayerWidgetOn(videoUrl: url)
                              : InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 3.0,
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.contain,
                                  placeholder:
                                      (context, url) => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.error,
                                            color: Colors.red,
                                            size: 50,
                                          ),
                                          Text(
                                            "Failed to load image",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              CachedNetworkImage.evictFromCache(
                                                url,
                                              );
                                              Navigator.of(context).pop();
                                              _showMediaDialog(
                                                context,
                                                url,
                                                false,
                                              );
                                            },
                                            child: Text("Retry"),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 40,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
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
            padding:
                imageUrl == "" && videoUrl == ""
                    ? EdgeInsets.all(8)
                    : EdgeInsets.all(3),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width / 1.5,
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
                            imageUrl != "" || videoUrl != ""
                                ? Radius.circular(5)
                                : Radius.circular(20),
                        topRight:
                            imageUrl != "" || videoUrl != ""
                                ? Radius.circular(5)
                                : Radius.circular(20),
                        bottomLeft: Radius.circular(0),
                        bottomRight:
                            imageUrl != "" || videoUrl != ""
                                ? Radius.circular(5)
                                : Radius.circular(20),
                      )
                      : BorderRadius.only(
                        topLeft:
                            imageUrl != "" || videoUrl != ""
                                ? Radius.circular(5)
                                : Radius.circular(20),
                        topRight:
                            imageUrl != "" || videoUrl != ""
                                ? Radius.circular(5)
                                : Radius.circular(20),
                        bottomLeft:
                            imageUrl != "" || videoUrl != ""
                                ? Radius.circular(5)
                                : Radius.circular(20),
                        bottomRight: Radius.circular(0),
                      ),
            ),
            child:
                videoUrl == "" && imageUrl == ""
                    ? Text(
                      message,
                      style: TextStyle(fontSize: 17, fontFamily: "Poppins"),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width / 1.5,
                              maxHeight: 200,
                            ),
                            width: MediaQuery.of(context).size.width / 1.5,

                            child: GestureDetector(
                              onTap:
                                  () =>
                                      videoUrl != ""
                                          ? _showMediaDialog(
                                            context,
                                            videoUrl,
                                            true,
                                          )
                                          : _showMediaDialog(
                                            context,
                                            imageUrl,
                                            false,
                                          ),
                              child:
                                  videoUrl != ""
                                      ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          VideoPlayerWidget(videoUrl: videoUrl),
                                          Container(
                                            color: Colors.black26,
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                          ),
                                        ],
                                      )
                                      : CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder:
                                            (context, url) =>
                                                CircularProgressIndicator(),
                                        errorWidget:
                                            (context, url, error) =>
                                                Icon(Icons.error),
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
