import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ NUEVO
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

// ⭐ IMPORTAR SERVICE LOCATOR
import 'core/di/service_locator.dart';

void main() async {
  // 1️⃣ Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ Inicializar Firebase
  await Firebase.initializeApp();

  // ✅ 2.5️⃣ NUEVO: Habilitar caché offline
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 3️⃣ ⭐ NUEVO: Configurar Service Locator
  // Esto inicializa TODOS los servicios en un solo lugar
  setupServiceLocator();

  // 4️⃣ Ejecutar app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ⭐ ACTUALIZADO: AuthProvider ahora usa getIt internamente
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Fincomu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
