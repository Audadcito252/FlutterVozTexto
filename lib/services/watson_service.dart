import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WatsonService {
  // TODO: Replace with your actual API Key and URL
  final String _apiKey = 'YOUR_API_KEY'; 
  final String _url = 'YOUR_SERVICE_URL/v1/recognize';

  Future<String> transcribeAudio(File audioFile) async {
    try {
      String basicAuth = 'apikey:$_apiKey';
      String encodedAuth = base64Encode(utf8.encode(basicAuth));

      final request = http.MultipartRequest('POST', Uri.parse(_url));
      
      request.headers.addAll({
        'Authorization': 'Basic $encodedAuth',
      });

      // Watson STT expects the file or binary data. 
      // We'll send it as a multipart file or direct body depending on the API variant.
      // Standard Watson STT often accepts raw binary with Content-Type.
      
      // Let's use direct binary upload for simplicity if supported, or multipart.
      // For "v1/recognize", we can often POST the file body directly.
      
      final fileBytes = await audioFile.readAsBytes();
      
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Basic $encodedAuth',
          'Content-Type': 'audio/wav', // Adjust based on actual recording format
        },
        body: fileBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Parse Watson response structure
        // { "results": [ { "alternatives": [ { "transcript": "hello world " } ] } ] }
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final results = data['results'] as List;
          final StringBuffer transcript = StringBuffer();
          for (var result in results) {
            if (result['alternatives'] != null && (result['alternatives'] as List).isNotEmpty) {
              transcript.write(result['alternatives'][0]['transcript']);
            }
          }
          return transcript.toString();
        }
        return "No speech detected.";
      } else {
        throw Exception('Failed to transcribe: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to Watson: $e');
    }
  }
}
