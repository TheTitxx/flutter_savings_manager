# Fincomu – App de Gestión Comunitaria

Fincomu es una aplicación móvil desarrollada en Flutter diseñada para la administración de reuniones, préstamos, votaciones, transacciones y control de usuarios dentro de una comunidad.
Incluye integración con Firebase, seguridad reforzada, manejo offline y operaciones atómicas para evitar inconsistencias en los datos.

# Características principales

✔ Autenticación de usuarios (Firebase Auth)

✔ Transacciones atómicas para pagos y votaciones

✔ Control de préstamos y transacciones financieras

✔ Gestión de reuniones, fechas y asistencia

✔ Caché offline habilitado (Firestore offline persistence)

✔ Firestore Rules configuradas para seguridad

✔ Índices de Firestore optimizados

✔ Arquitectura limpia con Service Locator (getIt)

✔ UI moderna y adaptable


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

  core/di/models

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
