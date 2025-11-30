# Fincomu – Community Management App

Fincomu is a Flutter-based mobile application designed to manage community meetings, loans, voting, financial transactions, and user control.
It includes Firebase integration, enhanced security, offline support, and atomic operations to prevent data inconsistencies.

# Main Features

✔ User authentication (Firebase Auth)

✔ Atomic transactions for payments and voting

✔ Loan and financial transaction management

✔ Meeting scheduling, date validation, and attendance tracking

✔ Offline cache enabled (Firestore offline persistence)

✔ Secure Firestore Rules configuration

✔ Optimized Firestore indexes

✔ Clean architecture using Service Locator (GetIt)

✔ Modern and responsive UI

# Tecnologías utilizadas

| Tecnología           | Uso                          |
| -------------------- | ---------------------------- |
| **Flutter**          | Framework principal          |
| **Dart**             | Lenguaje de programación     |
| **Firebase Auth**    | Inicio de sesión             |
| **Firestore**        | Base de datos en tiempo real |
| **Firebase Storage** | Archivos (si aplica)         |
| **Provider**         | Manejo de estado             |
| **GetIt**            | Inyección de dependencias    |

# Estructura del proyecto

    lib/
        core/di/models/
        models/
        providers/
        screens/
        services/
        widgets/
        main.dart

    firebase.json
    firestore.rules
    firestore.indexes.json
    pubspec.yaml

# Configuración del proyecto

1. Instalar dependencias
    
        flutter pub get

2. Agregar configuración de Firebase

    Asegúrate de incluir los archivos generados por FlutterFire CLI:

    - android/app/google-services.json
    - ios/Runner/GoogleService-Info.plist

3. Ejecutar la app

        flutter run

# Modo desarrollo

Comandos útiles:

        flutter clean
        flutter pub get
        flutter run --release

# Modo desarrollo
    
Plataformas soportadas

- Android ✔
- iOS ✔ (estructura lista, aunque no se compile hoy)

# Contribuciones

PRs, mejoras y sugerencias son bienvenidas.

# Licencia

Este proyecto es privado. No se permite el uso sin autorización.
