import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  // ⚠️ GANTI INI DENGAN IP LAPTOP KAMU!
  // Jika pakai Emulator Android: gunakan 'http://10.0.2.2:8000'
  // Jika pakai HP Fisik (colok USB): gunakan 'http://192.168.1.XX:8000' (sesuai ipconfig tadi)
  final String baseUrl = 'http://10.184.75.70:8000';  // Benar

  Future<String?> convertVoice(String audioPath, String characterName) async {
    try {
      String fileName = audioPath.split('/').last;

      // Siapkan data untuk dikirim
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioPath, filename: fileName),
        'character': characterName,
      });

      _logger.i("🚀 Mengirim audio ke: $baseUrl/convert");

      // Kirim ke Python
      Response response = await _dio.post(
        '$baseUrl/convert',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes, // Kita minta balikan berupa FILE (Bytes), bukan teks
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        _logger.i("✅ Sukses! Audio diterima dari server.");

        // Simpan file hasil olahan server ke HP
        final Directory tempDir = await getTemporaryDirectory();
        final String outputPath = '${tempDir.path}/result_$fileName';

        File file = File(outputPath);
        await file.writeAsBytes(response.data); // Tulis data binary ke file

        return outputPath; // Kembalikan lokasi file baru
      } else {
        _logger.e("❌ Server Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      _logger.e("❌ Koneksi Gagal: $e");
      // Tips: Kalau gagal di sini, biasanya karena IP salah atau HP & Laptop beda WiFi
      return null;
    }
  }
}