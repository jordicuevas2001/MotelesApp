import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [

                  /// Logo
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: gold),
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

                  /// Card Login
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        const Text(
                          "USUARIO",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Usuario",
                            hintStyle:
                                const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: inputColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

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
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "••••••••",
                            hintStyle:
                                const TextStyle(color: Colors.grey),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {},
                            ),
                            filled: true,
                            fillColor: inputColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.login),
                            label: const Text(
                              "Entrar al sistema",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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