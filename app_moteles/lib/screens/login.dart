import 'package:flutter/material.dart';
import 'package:app_moteles/main.dart';
import 'package:app_moteles/services/api_service.dart';
import 'package:app_moteles/screens/adminscreen/reportes_admin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool cargando = false;
  bool mostrarPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> iniciarSesion() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      mostrarMensaje(
        'Ingresa tu correo y contraseña',
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final respuesta = await ApiService.login(
        email,
        password,
      );

      if (!mounted) return;

      final usuario =
          respuesta['usuario'] as Map<String, dynamic>;

      final rol = usuario['rol']?.toString();

      print('==============================');
      print('LOGIN CORRECTO');
      print('ID: ${usuario['id']}');
      print('NOMBRE: ${usuario['name']}');
      print('EMAIL: ${usuario['email']}');
      print('ROL: $rol');
      print('MOTEL ID: ${usuario['motel_id']}');
      print('MOTEL: ${usuario['motel']}');
      print('==============================');

      // ========================================================
      // ADMINISTRADOR
      // ========================================================

      if (rol == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportesAdmin(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // USUARIO NORMAL
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MotelScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  // ============================================================
  // MENSAJE
  // ============================================================

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F141C);
    const cardColor = Color(0xFF171E2A);
    const inputColor = Color(0xFF222A39);
    const gold = Color(0xFFC58B2A);

    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),

              child: Column(
                children: [
                  // ==================================================
                  // LOGO
                  // ==================================================

                  Container(
                    width: 70,
                    height: 70,

                    decoration: BoxDecoration(
                      color: gold.withOpacity(.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: gold,
                      ),
                    ),

                    child: const Icon(
                      Icons.bed,
                      color: gold,
                      size: 34,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "SISTEMA DE CONTROL",
                    style: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 2,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Hotel Nocturno",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // ==================================================
                  // CARD LOGIN
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Iniciar sesión",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Ingresa tus credenciales para continuar",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // CORREO
                        // ==================================================

                        const Text(
                          "CORREO ELECTRÓNICO",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: emailController,

                          keyboardType:
                              TextInputType.emailAddress,

                          style: const TextStyle(
                            color: Colors.white,
                          ),

                          decoration: InputDecoration(
                            hintText:
                                "correo@ejemplo.com",

                            hintStyle:
                                const TextStyle(
                              color: Colors.grey,
                            ),

                            prefixIcon:
                                const Icon(
                              Icons.email_outlined,
                              color: Colors.grey,
                            ),

                            filled: true,
                            fillColor: inputColor,

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ==================================================
                        // CONTRASEÑA
                        // ==================================================

                        const Text(
                          "CONTRASEÑA",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: passwordController,

                          obscureText:
                              !mostrarPassword,

                          style: const TextStyle(
                            color: Colors.white,
                          ),

                          onSubmitted: (_) {
                            if (!cargando) {
                              iniciarSesion();
                            }
                          },

                          decoration: InputDecoration(
                            hintText: "••••••••",

                            hintStyle:
                                const TextStyle(
                              color: Colors.grey,
                            ),

                            prefixIcon:
                                const Icon(
                              Icons.lock_outline,
                              color: Colors.grey,
                            ),

                            suffixIcon:
                                IconButton(
                              icon: Icon(
                                mostrarPassword
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                                color: Colors.grey,
                              ),

                              onPressed: () {
                                setState(() {
                                  mostrarPassword =
                                      !mostrarPassword;
                                });
                              },
                            ),

                            filled: true,
                            fillColor: inputColor,

                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // BOTÓN
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 55,

                          child: ElevatedButton.icon(
                            onPressed:
                                cargando
                                    ? null
                                    : iniciarSesion,

                            icon: cargando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(
                                    Icons.login,
                                  ),

                            label: Text(
                              cargando
                                  ? "Iniciando sesión..."
                                  : "Entrar al sistema",

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor:
                                  Colors.black,

                              disabledBackgroundColor:
                                  gold.withOpacity(.5),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}