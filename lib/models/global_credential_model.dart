class GlobalCredentialModel {
  final int? id; // Es int porque en nuestra API de Python usamos un SERIAL de Postgres (número incremental)
  final String sitio;
  final String url;
  final String usuario;
  final String contrasena;

  GlobalCredentialModel({
    this.id,
    required this.sitio,
    required this.url,
    required this.usuario,
    required this.contrasena,
  });

  // Convierte el objeto a un Mapa para poder mandarlo como JSON a tu API de Python (POST)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sitio': sitio,
      'url': url,
      'usuario': usuario,
      'contrasena': contrasena,
    };
  }

  // Mapea la respuesta JSON que devuelve el servidor Linux (SELECT / GET) de vuelta a un objeto de Flutter
  factory GlobalCredentialModel.fromMap(Map<String, dynamic> map) {
    return GlobalCredentialModel(
      id: map['id'],
      sitio: map['sitio'] ?? '',
      url: map['url'] ?? '',
      usuario: map['usuario'] ?? '',
      contrasena: map['contrasena'] ?? '',
    );
  }
}