import 'package:chat_app/Widget/VideoChache.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPreviewWidget extends StatefulWidget {
  final String videoPathOrUrl; // Accepts both local file paths and URLs

  const VideoPreviewWidget({Key? key, required this.videoPathOrUrl})
    : super(key: key);

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      String videoPath;
      if (widget.videoPathOrUrl.startsWith('http')) {
        // Cache the video if it's a URL
        videoPath = await VideoCacheManager.getCachedVideoPath(
          widget.videoPathOrUrl,
        );
      } else {
        // Use the local file path directly
        videoPath = widget.videoPathOrUrl;
      }

      _controller = VideoPlayerController.file(File(videoPath))
        ..initialize().then((_) {
          _controller.setVolume(0); // Mute by default
          _controller.seekTo(Duration.zero); // Start from the beginning
          setState(() {
            _isInitialized = true;
          });
        });

      // Add listener for position updates
      _controller.addListener(() {
        setState(() {}); // Rebuild to update time display
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print("Error loading video: $e");
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(child: Icon(Icons.error, color: Colors.red));
    }

    if (_isDownloading) {
      return Center(child: CircularProgressIndicator());
    }

    return _isInitialized
        ? ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              // Semi-transparent overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black54,
                    ],
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
              ),
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    _controller.value.isPlaying
                        ? FontAwesomeIcons.pause
                        : FontAwesomeIcons.play,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              // Time display
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Progress indicator
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).primaryColor,
                    bufferedColor: Colors.white.withOpacity(0.5),
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        )
        : Center(child: CircularProgressIndicator());
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final localPath = await VideoCacheManager.getCachedVideoPath(
        widget.videoUrl,
      );
      if (!mounted) return;

      _controller = VideoPlayerController.file(File(localPath));
      await _controller.initialize();
      if (!mounted) return;

      _controller.setVolume(0);
      // Get the first frame but don't play
      await _controller.seekTo(Duration.zero);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
      print("Error loading video: $e");
    } finally {
      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(child: Icon(Icons.error, color: Colors.red));
    }

    if (_isDownloading) {
      return Center(child: CircularProgressIndicator());
    }

    return _isInitialized
        ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
        : Center(child: CircularProgressIndicator());
  }
}

class VideoPlayerWidgetOn extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidgetOn({Key? key, required this.videoUrl})
    : super(key: key);

  @override
  _VideoPlayerWidgetStateOn createState() => _VideoPlayerWidgetStateOn();
}

class _VideoPlayerWidgetStateOn extends State<VideoPlayerWidgetOn> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final localPath = await VideoCacheManager.getCachedVideoPath(
        widget.videoUrl,
      );
      _controller = VideoPlayerController.file(File(localPath));

      await _controller.initialize();
      _controller.setVolume(1.0);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print("Error loading video: $e");
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(child: Icon(Icons.error, color: Colors.red));
    }

    if (_isDownloading) {
      return Center(child: CircularProgressIndicator());
    }

    return _isInitialized
        ? GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Player
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),

              // Controls overlay
              if (_showControls)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black54,
                      ],
                      stops: [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),

              // Play/Pause button
              if (_showControls)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Progress bar and duration
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Video progress slider
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          colors: VideoProgressColors(
                            playedColor: Theme.of(context).primaryColor,
                            bufferedColor: Colors.white.withOpacity(0.5),
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),

                        // Duration text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        )
        : Center(child: CircularProgressIndicator());
  }
}
