import 'package:flutter/material.dart';
import 'models/credential_model.dart';
import 'services/storage_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final StorageService _storageService = StorageService();
  List<CredentialModel> _misClaves = [];
  
  // PIN maestro local ficticio para la demostración (en producción se guardaría cifrado)
  final String _pinMaestro = "1234"; 

  // Controladores de texto para el formulario
  final TextEditingController _sitioController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  // Estados de visibilidad
  bool _obscureFormContrasena = true;
  Map<String, bool> _clavesVisibles = {}; // Guarda qué tarjetas revelaron su contraseña

  @override
  void initState() {
    super.initState();
    _cargarClavesPersonales();
  }

  Future<void> _cargarClavesPersonales() async {
    final claves = await _storageService.obtenerCredenciales(); // Ajusta al nombre exacto de tu método
    setState(() {
      _misClaves = claves;
    });
  }

  // Guarda o Edita una clave
  Future<void> _guardarOEditarClave({String? editId}) async {
    if (_sitioController.text.isEmpty || _usuarioController.text.isEmpty || _contrasenaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena los campos obligatorios')),
      );
      return;
    }

    if (editId != null) {
      // Si estamos editando, borramos la versión vieja antes de meter la nueva
      await _storageService.eliminarCredencial(editId);
    }

    final credencial = CredentialModel(
      id: editId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sitio: _sitioController.text,
      url: _urlController.text,
      usuario: _usuarioController.text,
      contrasena: _contrasenaController.text,
    );

    await _storageService.guardarCredencial(credencial);
    
    _limpiarFormulario();
    _cargarClavesPersonales();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _limpiarFormulario() {
    _sitioController.clear();
    _urlController.clear();
    _usuarioController.clear();
    _contrasenaController.clear();
    _obscureFormContrasena = true;
  }

  // Abre el formulario tanto para crear como para editar
  void _mostrarFormulario({CredentialModel? antiguaCredencial}) {
    if (antiguaCredencial != null) {
      _sitioController.text = antiguaCredencial.sitio;
      _urlController.text = antiguaCredencial.url;
      _usuarioController.text = antiguaCredencial.usuario;
      _contrasenaController.text = antiguaCredencial.contrasena;
    } else {
      _limpiarFormulario();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder( // Nos permite refrescar el estado interno del ojo de la contraseña
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  antiguaCredencial != null ? 'Editar Credencial' : 'Añadir Credencial Personal', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 15),
                TextField(controller: _sitioController, decoration: const InputDecoration(labelText: 'Sitio o Servicio *')),
                TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'URL / Link (Opcional)')),
                TextField(controller: _usuarioController, decoration: const InputDecoration(labelText: 'Usuario o Correo *')),
                TextField(
                  controller: _contrasenaController, 
                  obscureText: _obscureFormContrasena,
                  decoration: InputDecoration(
                    labelText: 'Contraseña *',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureFormContrasena ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setModalState(() {
                          _obscureFormContrasena = !_obscureFormContrasena;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _guardarOEditarClave(editId: antiguaCredencial?.id),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: const Text('Guardar Cambios'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Validación del TOKEN/PIN para revelar la clave
  void _solicitarPinParaRevelar(String id, String contrasenaReal) {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validación de Seguridad'),
        content: TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Introduce tu PIN (Prueba: 1234)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (_pinController.text == _pinMaestro) {
                setState(() {
                  _clavesVisibles[id] = true; // Revela la clave en la lista
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN Incorrecto')),
                );
              }
            },
            child: const Text('Validar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _misClaves.isEmpty
          ? const Center(child: Text('No tienes claves personales guardadas.'))
          : ListView.builder(
              itemCount: _misClaves.length,
              itemBuilder: (context, index) {
                final item = _misClaves[index];
                final bool esVisible = _clavesVisibles[item.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(left: 15, right: 15, top: 10),
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key, color: Colors.blue),
                    title: Text(item.sitio, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('User: ${item.usuario}\nPass: ${esVisible ? item.contrasena : "••••••••"}\nLink: ${item.url.isEmpty ? "Ninguno" : item.url}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // BOTÓN VER CON PIN
                        IconButton(
                          icon: Icon(esVisible ? Icons.visibility : Icons.lock_outline, color: esVisible ? Colors.green : Colors.amber),
                          onPressed: () {
                            if (esVisible) {
                              setState(() => _clavesVisibles[item.id] = false); // Ocultar si ya era visible
                            } else {
                              _solicitarPinParaRevelar(item.id, item.contrasena);
                            }
                          },
                        ),
                        // BOTÓN EDITAR
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () => _mostrarFormulario(antiguaCredencial: item),
                        ),
                        // BOTÓN ELIMINAR
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _storageService.eliminarCredencial(item.id);
                            _cargarClavesPersonales();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      const Center(child: Text('🌐 Espacio del Equipo (Próximamente en la Nube)', style: TextStyle(fontSize: 16))),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Vault Manager'), elevation: 0),
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(onPressed: () => _mostrarFormulario(), child: const Icon(Icons.add))
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Personales'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Globales'),
        ],
      ),
    );
  }
}