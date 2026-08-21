import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class AiGatewayService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1/ai';

  Future<bool> indexDocument(String documentId, String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/index_document'));
      request.fields['document_id'] = documentId;
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType('application', 'pdf'),
      ));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error indexing document: $e');
      return false;
    }
  }

  Future<String> askDocument(String documentId, String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ask_document'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_id': documentId,
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'No answer provided.';
      } else {
        return 'Error: Server returned ${response.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to AI Gateway: $e';
    }
  }

  /// Sends recorded audio to the AI Server and returns a map containing the transcript and path to the MP3 response.
  Future<Map<String, String>?> sendVoiceChat(String documentId, String audioFilePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/voice_chat'));
      request.fields['document_id'] = documentId;
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFilePath,
        contentType: MediaType('audio', 'm4a'),
      ));

      var response = await request.send();
      
      if (response.statusCode == 200) {
        final transcript = response.headers['x-transcript'] ?? 'Voice message received.';
        
        // Save the audio response locally
        final bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final responseFilePath = '${tempDir.path}/ai_response.mp3';
        await File(responseFilePath).writeAsBytes(bytes);
        
        return {
          'transcript': transcript,
          'audioPath': responseFilePath,
        };
      }
      return null;
    } catch (e) {
      print('Error in voice chat: $e');
      return null;
    }
  }
}
