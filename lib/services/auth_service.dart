import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'core/service_result.dart';
import 'core/firebase_collections.dart';

/// Servicio especializado en autenticación y gestión de usuarios
///
/// Responsabilidades:
/// - Registro de nuevos usuarios
/// - Inicio de sesión
/// - Cierre de sesión
/// - Obtención de datos del usuario actual
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== GETTERS ====================

  /// Usuario actualmente autenticado (Firebase Auth)
  User? get currentUser => _auth.currentUser;

  /// UID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => currentUserId != null;

  // ==================== REGISTRO ====================

  /// Registra un nuevo usuario en Firebase Auth y Firestore
  ///
  /// Pasos:
  /// 1. Crea cuenta en Firebase Auth
  /// 2. Guarda datos adicionales en Firestore
  ///
  /// Retorna [ServiceResult<UserModel>] con el usuario creado o error
  Future<ServiceResult<UserModel>> registerUser({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure(ErrorMessages.authRegistrationFailed);
      }

      // 2. Crear documento de usuario en Firestore
      final newUser = UserModel(
        uid: credential.user!.uid,
        nombre: nombre,
        email: email,
        telefono: telefono,
        fechaRegistro: DateTime.now().toUtc(),
        esActivo: true,
      );

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(newUser.uid)
          .set(newUser.toMap());

      return ServiceResult.success(newUser);
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_getAuthErrorMessage(e.code), e);
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.authRegistrationFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== INICIO DE SESIÓN ====================

  /// Inicia sesión con email y contraseña
  ///
  /// Retorna [ServiceResult<UserModel>] con datos del usuario desde Firestore
  Future<ServiceResult<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar en Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure(ErrorMessages.authInvalidCredentials);
      }

      // 2. Obtener datos completos desde Firestore
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return ServiceResult.failure(
          'Usuario no encontrado en la base de datos',
        );
      }

      final user = UserModel.fromMap(userDoc.data()!);
      return ServiceResult.success(user);
    } on FirebaseAuthException catch (e) {
      return ServiceResult.failure(_getAuthErrorMessage(e.code), e);
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.authSignInFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== CIERRE DE SESIÓN ====================

  /// Cierra la sesión del usuario actual
  Future<ServiceResult<void>> signOut() async {
    try {
      await _auth.signOut();
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al cerrar sesión',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== OBTENER DATOS ====================

  /// Obtiene los datos completos del usuario actual desde Firestore
  Future<ServiceResult<UserModel>> getCurrentUserData() async {
    if (currentUserId == null) {
      return ServiceResult.failure(ErrorMessages.authNoUser);
    }

    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(currentUserId)
          .get();

      if (!doc.exists) {
        return ServiceResult.failure('Datos de usuario no encontrados');
      }

      final user = UserModel.fromMap(doc.data()!);
      return ServiceResult.success(user);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener datos del usuario',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Obtiene los datos de un usuario específico por su UID
  Future<ServiceResult<UserModel>> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return ServiceResult.failure('Usuario no encontrado');
      }

      final user = UserModel.fromMap(doc.data()!);
      return ServiceResult.success(user);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener usuario',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Obtiene los nombres de múltiples usuarios
  ///
  /// Retorna un mapa [userId -> nombre]
  Future<ServiceResult<Map<String, String>>> getUserNames(
    List<String> userIds,
  ) async {
    try {
      final nombres = <String, String>{};

      for (final userId in userIds) {
        final result = await getUserById(userId);
        if (result.isSuccess) {
          nombres[userId] = result.data!.nombre;
        }
      }

      return ServiceResult.success(nombres);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener nombres de usuarios',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Convierte códigos de error de Firebase Auth a mensajes amigables
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación: $code';
    }
  }
}
