import '../core/models/base_model.dart';

/// ✅ MODELO OPTIMIZADO con BaseModel
class UserModel extends BaseModel {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final DateTime fechaRegistro;
  final bool esActivo;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.fechaRegistro,
    this.esActivo = true,
  });

  // ==================== SERIALIZACIÓN ====================

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'esActivo': esActivo,
    };
  }

  /// ✅ FACTORY METHOD simplificado con BaseModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map.getOrDefault('uid', ''),
      nombre: map.getOrDefault('nombre', ''),
      email: map.getOrDefault('email', ''),
      telefono: map.getOrDefault('telefono', ''),
      fechaRegistro: BaseModel.parseDate(map['fechaRegistro']),
      esActivo: map.getOrDefault('esActivo', true),
    );
  }

  // ==================== COPYWITTH ====================

  UserModel copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? telefono,
    DateTime? fechaRegistro,
    bool? esActivo,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      esActivo: esActivo ?? this.esActivo,
    );
  }

  // ==================== GETTERS ÚTILES ====================

  /// Primera letra del nombre en mayúscula
  String get iniciales {
    if (nombre.isEmpty) return '?';
    final palabras = nombre.trim().split(' ');
    if (palabras.length == 1) {
      return palabras[0][0].toUpperCase();
    }
    return palabras[0][0].toUpperCase() + palabras[1][0].toUpperCase();
  }

  /// Tiempo como miembro (en días)
  int get diasComoMiembro {
    return DateTime.now().difference(fechaRegistro).inDays;
  }

  /// Usuario es nuevo (menos de 7 días)
  bool get esNuevo => diasComoMiembro < 7;

  // ==================== VALIDACIONES ====================

  /// Valida si el email tiene formato correcto
  bool get emailValido {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Valida si el teléfono tiene formato básico
  bool get telefonoValido {
    return telefono.length >= 10;
  }

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserModel(uid: $uid, nombre: $nombre, email: $email)';
}
