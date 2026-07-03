import 'package:flutter/material.dart';
import 'models/credential_model.dart';
import 'models/global_credential_model.dart';
import 'services/storage_services.dart';
import 'services/api_services.dart';

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
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// PANTALLA DE LOGIN Y CONFIGURACIÓN DE PIN
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  bool _tienePinRegistrado = false;
  bool _estaCargando = true;
  String? _pinGuardado;

  @override
  void initState() {
    super.initState();
    _comprobarEstadoPin();
  }

  // Verifica si ya existe un PIN en el almacenamiento seguro
  Future<void> _comprobarEstadoPin() async {
    // Nota: Asumiendo que añades el soporte en StorageService o usas la lectura nativa.
    // Para asegurar compatibilidad inmediata si tu StorageService solo maneja credenciales,
    // puedes usar una clave directa en Flutter Secure Storage dentro de tu clase de servicio.
    final pin = await _storageService.obtenerPinMaestro(); 
    
    setState(() {
      if (pin != null && pin.isNotEmpty) {
        _tienePinRegistrado = true;
        _pinGuardado = pin;
      } else {
        _tienePinRegistrado = false;
      }
      _estaCargando = false;
    });
  }

  // Registra el nuevo PIN por primera vez
  Future<void> _registrarNuevoPin() async {
    if (_pinController.text.isEmpty || _confirmPinController.text.isEmpty) {
      _mostrarMensaje('Por favor, llena ambos campos');
      return;
    }
    if (_pinController.text.length < 4) {
      _mostrarMensaje('El PIN debe tener al menos 4 dígitos');
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      _mostrarMensaje('Los PIN no coinciden');
      return;
    }

    await _storageService.guardarPinMaestro(_pinController.text);
    _mostrarMensaje('PIN guardado correctamente', esExito: true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Valida el PIN de entrada normal
  void _verificarAcceso() {
    if (_pinController.text == _pinGuardado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      _pinController.clear();
      _mostrarMensaje('PIN incorrecto. Acceso denegado.');
    }
  }

  void _mostrarMensaje(String texto, {bool esExito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esExito ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SingleChildScrollView(
            child: _tienePinRegistrado ? _buildPantallaLogin() : _buildPantallaRegistro(),
          ),
        ),
      ),
    );
  }

  // Interfaz de Desbloqueo Normal
  Widget _buildPantallaLogin() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.security, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 20),
        const Text('Vault Manager', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Introduce tu PIN para desbloquear la bóveda', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 22, letterSpacing: 8),
          decoration: const InputDecoration(counterText: "", hintText: "••••", hintStyle: TextStyle(letterSpacing: 0)),
          onSubmitted: (_) => _verificarAcceso(),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _verificarAcceso,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Desbloquear', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Interfaz de Configuración Inicial (Primer inicio)
  Widget _buildPantallaRegistro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_open_rounded, size: 80, color: Colors.greenAccent),
        const SizedBox(height: 20),
        const Text('Configurar Bóveda', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Crea un PIN de seguridad personal para proteger tus datos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 20, letterSpacing: 6),
          decoration: const InputDecoration(counterText: "", labelText: 'Nuevo PIN numérico', labelStyle: TextStyle(letterSpacing: 0)),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _confirmPinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 20, letterSpacing: 6),
          decoration: const InputDecoration(counterText: "", labelText: 'Confirmar PIN', labelStyle: TextStyle(letterSpacing: 0)),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _registrarNuevoPin,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green),
          child: const Text('Establecer PIN y Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ==========================================
// VISTA PRINCIPAL (HOME)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  List<CredentialModel> _misClaves = [];
  List<GlobalCredentialModel> _globales = [];
  
  CredentialModel? _personalEnEdicion;
  GlobalCredentialModel? _globalEnEdicion;

  final TextEditingController _sitioController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _pinValidationController = TextEditingController();

  bool _obscureFormContrasena = true;
  final Map<String, bool> _clavesPersonalesVisibles = {};
  final Map<int, bool> _clavesGlobalesVisibles = {};

  @override
  void initState() {
    super.initState();
    _cargarClavesPersonales();
  }

  Future<void> _cargarClavesPersonales() async {
    final claves = await _storageService.obtenerCredenciales();
    setState(() {
      _misClaves = claves;
    });
  }

  Future<void> _cargarClavesGlobales() async {
    final claves = await _apiService.obtenerGlobales();
    setState(() {
      _globales = claves;
    });
  }

  Future<void> _procesarGuardado() async {
    if (_sitioController.text.isEmpty || _usuarioController.text.isEmpty || _contrasenaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena los campos obligatorios')),
      );
      return;
    }

    if (_currentIndex == 0) {
      if (_personalEnEdicion != null) {
        final credencialActualizada = CredentialModel(
          id: _personalEnEdicion!.id,
          sitio: _sitioController.text,
          url: _urlController.text,
          usuario: _usuarioController.text,
          contrasena: _contrasenaController.text,
        );
        await _storageService.guardarCredencial(credencialActualizada);
      } else {
        final nuevaCredencial = CredentialModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sitio: _sitioController.text,
          url: _urlController.text,
          usuario: _usuarioController.text,
          contrasena: _contrasenaController.text,
        );
        await _storageService.guardarCredencial(nuevaCredencial);
      }
      _cargarClavesPersonales();
    } else {
      if (_globalEnEdicion != null) {
        final globalActualizada = GlobalCredentialModel(
          id: _globalEnEdicion!.id,
          sitio: _sitioController.text,
          url: _urlController.text,
          usuario: _usuarioController.text,
          contrasena: _contrasenaController.text,
        );
        bool exito = await _apiService.actualizarGlobal(globalActualizada);
        if (exito) {
          _cargarClavesGlobales();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar en el servidor Linux')),
          );
        }
      } else {
        final nuevaGlobal = GlobalCredentialModel(
          sitio: _sitioController.text,
          url: _urlController.text,
          usuario: _usuarioController.text,
          contrasena: _contrasenaController.text,
        );
        bool exito = await _apiService.guardarGlobal(nuevaGlobal);
        if (exito) {
          _cargarClavesGlobales();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No se pudo conectar con el servidor Linux')),
          );
        }
      }
    }

    _limpiarFormulario();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _limpiarFormulario() {
    _sitioController.clear();
    _urlController.clear();
    _usuarioController.clear();
    _contrasenaController.clear();
    _obscureFormContrasena = true;
    _personalEnEdicion = null;
    _globalEnEdicion = null;
  }

  void _cargarDatosParaEditar(dynamic credencial, bool isGlobal) {
    setState(() {
      if (isGlobal) {
        _globalEnEdicion = credencial as GlobalCredentialModel;
        _sitioController.text = _globalEnEdicion!.sitio;
        _urlController.text = _globalEnEdicion!.url;
        _usuarioController.text = _globalEnEdicion!.usuario;
        _contrasenaController.text = _globalEnEdicion!.contrasena;
      } else {
        _personalEnEdicion = credencial as CredentialModel;
        _sitioController.text = _personalEnEdicion!.sitio;
        _urlController.text = _personalEnEdicion!.url;
        _usuarioController.text = _personalEnEdicion!.usuario;
        _contrasenaController.text = _personalEnEdicion!.contrasena;
      }
    });
    _mostrarFormularioAgregar(context, esEdicion: true);
  }

  void _mostrarFormularioAgregar(BuildContext context, {bool esEdicion = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esEdicion 
                    ? 'Editar Credencial 📝' 
                    : (_currentIndex == 0 ? 'Añadir Credencial Personal 🔒' : 'Añadir Credencial Global 🌐'), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              TextField(controller: _sitioController, decoration: const InputDecoration(labelText: 'Sitio o Servicio *')),
              TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'URL / Link (Opcional)')),
              TextField(controller: _usuarioController, decoration: const InputDecoration(labelText: 'Usuario o Correo *')),
              TextField(
                controller: _contrasenaController, 
                obscureText: _obscureFormContrasena,
                decoration: const InputDecoration(labelText: 'Contraseña *'),
              ),
              const SizedBox(height: 20),
              ButtonTheme(
                child: ElevatedButton(
                  onPressed: _procesarGuardado,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: Text(esEdicion ? 'Actualizar cambios' : 'Guardar de forma segura'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (!esEdicion) _limpiarFormulario();
    });
  }

  // Solicita la validación leyendo dinámicamente el PIN personalizado guardado en el hardware
  void _solicitarPinParaRevelar(dynamic id, bool isGlobal) {
    _pinValidationController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validación de Seguridad'),
        content: TextField(
          controller: _pinValidationController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Introduce tu PIN de seguridad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final pinCorrecto = await _storageService.obtenerPinMaestro();
              if (_pinValidationController.text == pinCorrecto) {
                setState(() {
                  if (isGlobal) {
                    _clavesGlobalesVisibles[id] = true;
                  } else {
                    _clavesPersonalesVisibles[id] = true;
                  }
                });
                if (!mounted) return;
                Navigator.pop(context);
              } else {
                if (!mounted) return;
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
      // 🔒 VISTA 1: PERSONALES
      _misClaves.isEmpty
          ? const Center(child: Text('No tienes claves personales guardadas.'))
          : ListView.builder(
              itemCount: _misClaves.length,
              itemBuilder: (context, index) {
                final item = _misClaves[index];
                final bool esVisible = _clavesPersonalesVisibles[item.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(left: 15, right: 15, top: 10),
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline, color: Colors.blue),
                    title: Text(item.sitio, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('User: ${item.usuario}\nPass: ${esVisible ? item.contrasena : "••••••••"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () => _cargarDatosParaEditar(item, false),
                        ),
                        IconButton(
                          icon: Icon(esVisible ? Icons.visibility : Icons.lock, color: esVisible ? Colors.green : Colors.amber),
                          onPressed: () {
                            if (esVisible) {
                              setState(() => _clavesPersonalesVisibles[item.id] = false);
                            } else {
                              _solicitarPinParaRevelar(item.id, false); // Ahora también pide el PIN personalizado localmente
                            }
                          },
                        ),
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
      
      // 🌐 VISTA 2: GLOBALES (SERVIDOR LINUX)
      _globales.isEmpty
          ? const Center(child: Text('No hay claves globales en el servidor o servidor apagado.'))
          : ListView.builder(
              itemCount: _globales.length,
              itemBuilder: (context, index) {
                final item = _globales[index];
                final bool esVisible = _clavesGlobalesVisibles[item.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(left: 15, right: 15, top: 10),
                  child: ListTile(
                    leading: const Icon(Icons.dns, color: Colors.purpleAccent),
                    title: Text(item.sitio, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('User: ${item.usuario}\nPass: ${esVisible ? item.contrasena : "••••••••"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () => _cargarDatosParaEditar(item, true),
                        ),
                        IconButton(
                          icon: Icon(esVisible ? Icons.visibility : Icons.security, color: esVisible ? Colors.green : Colors.deepOrangeAccent),
                          onPressed: () {
                            if (esVisible) {
                              setState(() => _clavesGlobalesVisibles[item.id!] = false);
                            } else {
                              _solicitarPinParaRevelar(item.id, true);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            if (item.id != null) {
                              bool exito = await _apiService.eliminarGlobal(item.id!.toString());
                              if (exito) _cargarClavesGlobales();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Vault Manager - Personal' : 'Vault Manager - Servidor Local'),
        elevation: 0,
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargarClavesGlobales,
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _limpiarFormulario();
          _mostrarFormularioAgregar(context);
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            _cargarClavesGlobales();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Personales'),
          BottomNavigationBarItem(icon: Icon(Icons.dns), label: 'Globales'),
        ],
      ),
    );
  }
}