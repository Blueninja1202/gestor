import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/global_credential_model.dart'; // El modelo global que creamos antes

class ApiService {
  // ⚠️ IMPORTANTE: Reemplaza esta IP por la IP PRIVADA local de tu máquina Linux
  // Si estás usando el emulador de Android, NO uses "localhost" porque el emulador pensará que es él mismo.
  // Debe ser la IP de tu Linux en el router (ej: 192.168.1.45)
  final String baseUrl = "http://localhost:8000";

  // 1. OBTENER LAS CLAVES DESDE EL SERVIDOR LINUX
  Future<List<GlobalCredentialModel>> obtenerGlobales() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/globales'));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => GlobalCredentialModel.fromMap(item)).toList();
      } else {
        throw Exception("Error al cargar datos del servidor");
      }
    } catch (e) {
      print("Error de conexión: $e");
      return [];
    }
  }

  // 2. GUARDAR UNA NUEVA CLAVE EN EL SERVIDOR
  Future<bool> guardarGlobal(GlobalCredentialModel credencial) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/globales'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(credencial.toMap()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error al guardar: $e");
      return false;
    }
  }

  // 3. ELIMINAR UNA CLAVE EN EL SERVIDOR
  Future<bool> eliminarGlobal(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/globales/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Error al eliminar: $e");
      return false;
    }
  }

  // 4. ACTUALIZAR UNA CLAVE EXISTENTE EN EL SERVIDOR
  Future<bool> actualizarGlobal(GlobalCredentialModel credencial) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/globales/${credencial.id}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(credencial.toMap()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar: $e");
      return false;
    }
  }

}