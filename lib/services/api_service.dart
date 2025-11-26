import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ IMPORTANTE: Configura la URL según tu entorno
  // - Web: 'http://localhost:8000'
  // - Android Emulator: 'http://10.0.2.2:8000'
  // - iOS Simulator: 'http://localhost:8000'
  // - Dispositivo físico: 'http://TU_IP_LOCAL:8000' (ej: 'http://192.168.1.100:8000')
  
  static const String baseUrl = 'http://localhost:8000';
  
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
  Future<Map<String, dynamic>> transcribeAudio(File audioFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/transcribe'),
      );
      
      // Agregar el archivo de audio
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
        ),
      );
      
      print('Enviando audio a: $baseUrl/api/transcribe');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // El backend retorna: {titulo, texto, id_documento, fecha}
        return data;
      } else {
        throw Exception('Error en transcripción: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error en transcribeAudio: $e');
      throw Exception('Error conectando al servidor: $e');
    }
  }
  
  /// Crea una nota completa (transcribe el audio y lo guarda en Cloudant)
  /// NOTA: El endpoint /api/transcribe ya hace esto automáticamente
  /// Este método existe por compatibilidad pero redirige a transcribeAudio
  Future<Map<String, dynamic>> createNote(File audioFile, {String? text}) async {
    return transcribeAudio(audioFile);
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
