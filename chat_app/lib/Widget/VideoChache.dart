import 'package:chat_app/Widget/VideoCacheDatabase.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoCacheManager {
  static final _dbHelper = VideoCacheDatabase();

  static Future<String> getCachedVideoPath(String url) async {
    // Check if the file path is already in the database
    final cachedFilePath = await _dbHelper.getVideoFilePath(url);

    if (cachedFilePath != null && File(cachedFilePath).existsSync()) {
      return cachedFilePath;
    }

    // Download the video and save it as a file
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      // Save the video to a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          url.split('/').last; // Extract the file name from the URL
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(response.data!);

      // Save the file path to the database
      await _dbHelper.saveVideo(url, filePath);

      return filePath;
    } catch (e) {
      throw Exception("Failed to cache video: $e");
    }
  }
}
