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

    // Helper function to get the appropriate status icon
    Widget _getStatusIcon() {
      if (isComming)
        return SizedBox.shrink(); // No status icon for incoming messages

      switch (status) {
        case 'pending':
          return Icon(Icons.access_time, color: Colors.white70, size: 15);
        case 'sent':
          return Icon(Icons.check, color: Colors.white70, size: 15);
        case 'delivered':
          return Icon(Icons.done_all, color: Colors.white70, size: 15);
        case 'read':
          return Icon(
            Icons.done_all,
            color: Colors.blue[300]!, // Blue tick for read messages
            size: 15,
          );
        case 'failed':
          return Icon(Icons.error_outline, color: Colors.red[300], size: 15);
        default:
          return Icon(Icons.check, color: Colors.white70, size: 15);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment:
            isComming ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Stack(
              children: [
                Container(
                  margin:
                      isComming
                          ? const EdgeInsets.only(left: 0, right: 40)
                          : const EdgeInsets.only(left: 40, right: 0),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  decoration: BoxDecoration(
                    gradient:
                        isComming
                            ? LinearGradient(
                              colors: [Colors.white, Colors.grey[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : LinearGradient(
                              colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(2, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft:
                          isComming ? Radius.circular(0) : Radius.circular(18),
                      bottomRight:
                          isComming ? Radius.circular(18) : Radius.circular(0),
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width / 1.9,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty || videoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: GestureDetector(
                              onTap:
                                  () =>
                                      videoUrl.isNotEmpty
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
                                  videoUrl.isNotEmpty
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
                                        width: 160,
                                        height: 120,
                                        placeholder:
                                            (context, url) => Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget:
                                            (context, url, error) =>
                                                Icon(Icons.error),
                                      ),
                            ),
                          ),
                        ),
                      if (message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 16,
                              color: isComming ? Colors.black87 : Colors.white,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isComming ? Colors.grey[500] : Colors.white70,
                            ),
                          ),
                          if (!isComming) ...[
                            SizedBox(width: 4),
                            _getStatusIcon(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Bubble tail
                Positioned(
                  bottom: 0,
                  left: isComming ? 8 : null,
                  right: isComming ? null : 8,
                  child: CustomPaint(
                    painter: BubbleTailPainter(
                      color: isComming ? Colors.white : Color(0xFF128C7E),
                      isComming: isComming,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isComming;
  BubbleTailPainter({required this.color, required this.isComming});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isComming) {
      path.moveTo(0, 0);
      path.lineTo(12, 6);
      path.lineTo(0, 18);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      path.moveTo(12, 0);
      path.lineTo(0, 6);
      path.lineTo(12, 18);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
