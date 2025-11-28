import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // 💡 Backend Local con fix para audio de navegadores
  // static const String baseUrl = 'http://localhost:8080';
  
  // ⚠️ API de Producción (requiere actualizar con el fix de formato de audio)
  static const String baseUrl = 'https://voznota.236n1v422v4y.br-sao.codeengine.appdomain.cloud';
  
  /// Health check del servidor
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking server health: $e');
      return false;
    }
  }
  
  /// Transcribe un archivo de audio usando Watson (transcribe + guarda en Cloudant)
  /// Este método usa el endpoint del backend VozNota que hace ambas cosas
  Future<Map<String, dynamic>> transcribeAudio(String audioPath, Uint8List audioBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/transcribe'),
      );
      
      print('📤 Preparando envío de audio...');
      print('   Ruta del archivo: $audioPath');
      print('   Tamaño del archivo: ${audioBytes.length} bytes');
      
      if (audioBytes.isEmpty) {
        throw Exception('El archivo de audio está vacío (0 bytes)');
      }
      
      // Agregar el archivo de audio con content-type explícito
      final multipartFile = http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: 'audio.wav',
        contentType: MediaType('audio', 'wav'), // Forzar content-type WAV
      );
      
      request.files.add(multipartFile);
      
      print('   Content-Type: ${multipartFile.contentType}');
      print('📡 Enviando audio a: $baseUrl/api/transcribe');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // El backend retorna: {titulo, texto, id_documento, fecha}
        return data;
      } else {
        // Extraer mensaje de error del backend
        String errorMsg = 'Error al transcribir el audio';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['detail'] ?? errorMsg;
        } catch (_) {
          errorMsg = 'Error ${response.statusCode}';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Error en transcribeAudio: $e');
      // Si ya es una excepción con mensaje personalizado, relanzarla
      if (e is Exception) rethrow;
      throw Exception('No se puede conectar al servidor');
    }
  }
  
  /// Crea una nota completa (transcribe el audio y lo guarda en Cloudant)
  /// NOTA: El endpoint /api/transcribe ya hace esto automáticamente
  /// Este método existe por compatibilidad pero redirige a transcribeAudio
  Future<Map<String, dynamic>> createNote(String audioPath, Uint8List audioBytes, {String? text}) async {
    return transcribeAudio(audioPath, audioBytes);
  }
  
  /// Obtiene todas las notas guardadas en Cloudant
  Future<List<Map<String, dynamic>>> getNotes({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notes?limit=$limit'),
      );
      
      print('Obteniendo notas desde: $baseUrl/api/notes');
      print('Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error obteniendo notas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getNotes: $e');
      throw Exception('Error: $e');
    }
  }
  
  /// Obtiene una nota específica por ID
  Future<Map<String, dynamic>> getNoteById(String noteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/notes/$noteId'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Nota no encontrada');
      } else {
        throw Exception('Error obteniendo nota: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getNoteById: $e');
      throw Exception('Error: $e');
    }
  }
  
  /// Elimina una nota de Cloudant
  Future<void> deleteNote(String noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notes/$noteId'),
      );
      
      print('Eliminando nota: $baseUrl/api/notes/$noteId');
      print('Status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Error eliminando nota: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en deleteNote: $e');
      throw Exception('Error: $e');
    }
  }
}
