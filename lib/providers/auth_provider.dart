import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

// ⭐ IMPORTAR SERVICE LOCATOR
import '../core/di/service_locator.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

/// 🔐 AUTH PROVIDER - REFACTORIZADO CON SERVICE LOCATOR
///
/// ✅ ANTES: Creaba FirebaseService internamente (acoplamiento fuerte)
/// ✅ AHORA: Usa getIt para obtener servicios (desacoplado, testeable)
///
/// Ventajas:
/// - Fácil de testear (inyectar mocks)
/// - No crea múltiples instancias de servicios
/// - Más limpio y mantenible
class AuthProvider with ChangeNotifier {
  // ⭐ NUEVO: Obtener servicios desde Service Locator
  final AuthService _authService = getIt<AuthService>();
  final GroupService _groupService = getIt<GroupService>();

  // Estado del provider
  UserModel? _currentUser;
  GroupModel? _selectedGroup;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  GroupModel? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // ==================== AUTENTICACIÓN ====================

  /// Registrar nuevo usuario
  Future<bool> register({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    // ⭐ NUEVO: Llamar servicio con manejo de ServiceResult
    final result = await _authService.registerUser(
      email: email,
      password: password,
      nombre: nombre,
      telefono: telefono,
    );

    if (result.isSuccess) {
      _currentUser = result.data;
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    // ⭐ NUEVO: Llamar servicio con manejo de ServiceResult
    final result = await _authService.signIn(email: email, password: password);

    if (result.isSuccess) {
      _currentUser = result.data;
      _setLoading(false);
      notifyListeners();
      await syncUserData();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    // ⭐ NUEVO: Llamar servicio
    await _authService.signOut();
    _currentUser = null;
    _selectedGroup = null;
    notifyListeners();
  }

  /// Cargar datos del usuario actual
  Future<void> loadCurrentUser() async {
    _setLoading(true);

    // ⭐ NUEVO: Llamar servicio con manejo de ServiceResult
    final result = await _authService.getCurrentUserData();

    if (result.isSuccess) {
      _currentUser = result.data;
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Sincronizar datos del usuario
  Future<void> syncUserData() async {
    if (_currentUser == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Recargar usuario
      final userResult = await _authService.getCurrentUserData();
      if (userResult.isSuccess) {
        _currentUser = userResult.data;
      }

      // 2. Recargar grupo si existe
      if (_selectedGroup != null) {
        final groupResult = await _groupService.getGroup(_selectedGroup!.id);
        if (groupResult.isSuccess) {
          _selectedGroup = groupResult.data;
        }
      }

      debugPrint('✅ Sincronización completada');
    } catch (e) {
      debugPrint('❌ Error en sincronización: $e');
      _errorMessage = 'Error al sincronizar datos';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Forzar recarga completa
  Future<void> forceRefresh() async {
    await syncUserData();
  }

  // ==================== GRUPOS ====================

  /// Crear nuevo grupo
  Future<GroupModel?> createGroup({
    required String nombre,
    required String descripcion,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    // ⭐ NUEVO: Llamar servicio con manejo de ServiceResult
    final result = await _groupService.createGroup(
      nombre: nombre,
      descripcion: descripcion,
    );

    if (result.isSuccess) {
      _selectedGroup = result.data;
      _setLoading(false);
      notifyListeners();
      return result.data;
    } else {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return null;
    }
  }

  /// Unirse a un grupo
  Future<bool> joinGroup(String codigoInvitacion) async {
    _setLoading(true);
    _errorMessage = null;

    // ⭐ NUEVO: Llamar servicio con manejo de ServiceResult
    final result = await _groupService.joinGroup(codigoInvitacion);

    if (result.isSuccess) {
      _errorMessage = null;
      _setLoading(false);
      await syncUserData();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage;
      _setLoading(false);
      return false;
    }
  }

  /// Seleccionar grupo actual
  void selectGroup(GroupModel group) {
    _selectedGroup = group;
    notifyListeners();
  }

  /// Recargar grupo actual
  Future<void> reloadSelectedGroup() async {
    if (_selectedGroup == null) return;

    final result = await _groupService.getGroup(_selectedGroup!.id);

    if (result.isSuccess) {
      _selectedGroup = result.data;
      notifyListeners();
    }
  }

  /// Verificar si es presidente
  bool get isPresident {
    if (_selectedGroup == null || _currentUser == null) return false;
    return _selectedGroup!.presidenteId == _currentUser!.uid;
  }

  // ==================== UTILIDADES ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
