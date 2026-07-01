class CredentialModel {
  final String id;
  final String sitio;
  final String url;
  final String usuario;
  final String contrasena;

  // Constructor (El equivalente al constructor en C++)
  CredentialModel({
    required this.id,
    required this.sitio,
    required this.url,
    required this.usuario,
    required this.contrasena,
  });

  // Método para convertir nuestro objeto a un Mapa (tipo JSON) para poder guardarlo
  Map<String, String> toMap() {
    return {
      'id': id,
      'sitio': sitio,
      'url': url,
      'usuario': usuario,
      'contrasena': contrasena,
    };
  }

  // Constructor de fábrica para reconstruir el objeto cuando lo leamos del almacenamiento
  factory CredentialModel.fromMap(Map<String, dynamic> map) {
    return CredentialModel(
      id: map['id'] ?? '',
      sitio: map['sitio'] ?? '',
      url: map['url'] ?? '',
      usuario: map['usuario'] ?? '',
      contrasena: map['contrasena'] ?? '',
    );
  }
}