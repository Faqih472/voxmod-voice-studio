import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();
  final String baseUrl = 'http://10.61.202.70:8000'; // Sesuaikan IP

  Future<String?> convertVoice(
      String audioPath,
      String characterName,
      String modelFilename,
      String indexFilename,
      int pitch // 👈 TAMBAHAN PARAMETER BARU
      ) async {
    try {
      String fileName = audioPath.split('/').last;

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioPath, filename: fileName),
        'character': characterName,
        'model_name': modelFilename,
        'index_name': indexFilename,
        'pitch': pitch, // 👈 KIRIM PITCH KE PYTHON
      });

      _logger.i("🚀 Mengirim ke Server. Model: $modelFilename | Pitch: $pitch");

      Response response = await _dio.post(
        '$baseUrl/convert',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final String outputPath = '${tempDir.path}/result_$fileName';
        File file = File(outputPath);
        await file.writeAsBytes(response.data);
        return outputPath;
      } else {
        _logger.e("❌ Server Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _logger.e("❌ Koneksi Gagal: $e");
      return null;
    }
  }
}
