import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credential_model.dart';

class StorageService {
  // Inicializamos el almacenamiento seguro nativo
  final _secureStorage = const FlutterSecureStorage();
  
  // Usaremos una llave fija en el storage para guardar la lista completa empaquetada
  final String _storageKey = 'mis_claves_personales';

  // 1. GUARDAR CLAVE
  Future<void> guardarCredencial(CredentialModel nuevaCredencial) async {
    // Primero leemos las que ya existen
    List<CredentialModel> actuales = await obtenerCredenciales();
    
    // Añadimos la nueva al array
    actuales.add(nuevaCredencial);
    
    // Convertimos la lista de objetos a una lista de Mapas, y luego a un String JSON
    List<Map<String, String>> mapas = actuales.map((c) => c.toMap()).toList();
    String jsonString = jsonEncode(mapas);
    
    // Lo guardamos encriptado a nivel de hardware
    await _secureStorage.write(key: _storageKey, value: jsonString);
  }

  // 2. LEER TODAS LAS CLAVES
  Future<List<CredentialModel>> obtenerCredenciales() async {
    String? jsonString = await _secureStorage.read(key: _storageKey);
    
    // Si no hay nada guardado todavía, retornamos una lista vacía
    if (jsonString == null) return [];
    
    // Si hay datos, decodificamos el JSON string a una lista dinámica
    List<dynamic> datosDecodificados = jsonDecode(jsonString);
    
    // Mapeamos cada elemento del JSON de vuelta a nuestro modelo de objeto
    return datosDecodificados
        .map((item) => CredentialModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  // 3. ELIMINAR CLAVE POR ID
  Future<void> eliminarCredencial(String id) async {
    List<CredentialModel> actuales = await obtenerCredenciales();
    // Filtramos la lista para remover la credencial que coincida con el ID
    actuales.removeWhere((c) => c.id == id);
    
    List<Map<String, String>> mapas = actuales.map((c) => c.toMap()).toList();
    String jsonString = jsonEncode(mapas);
    
    await _secureStorage.write(key: _storageKey, value: jsonString);
  }

  // Llave única para aislar el PIN dentro del almacenamiento encriptado
  static const _keyPinMaestro = 'user_pin_maestro';

  // 1. Guarda el nuevo PIN ingresado por el usuario
  Future<void> guardarPinMaestro(String pin) async {
    await _secureStorage.write(key: _keyPinMaestro, value: pin);
  }

  // 2. Recupera el PIN guardado en el hardware del dispositivo
  Future<String?> obtenerPinMaestro() async {
    return await _secureStorage.read(key: _keyPinMaestro);
  }

}