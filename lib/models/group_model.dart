import '../core/models/base_model.dart';

/// ✅ GROUP MODEL OPTIMIZADO
class GroupModel extends BaseModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String codigoInvitacion;
  final String presidenteId;
  final List<String> miembrosIds;
  final double totalAhorros;
  final double totalPrestamos;
  final DateTime fechaCreacion;
  final bool esActivo;

  GroupModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.codigoInvitacion,
    required this.presidenteId,
    required this.miembrosIds,
    this.totalAhorros = 0.0,
    this.totalPrestamos = 0.0,
    required this.fechaCreacion,
    this.esActivo = true,
  });

  // ==================== SERIALIZACIÓN ====================

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'codigoInvitacion': codigoInvitacion,
      'presidenteId': presidenteId,
      'miembrosIds': miembrosIds,
      'totalAhorros': totalAhorros,
      'totalPrestamos': totalPrestamos,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'esActivo': esActivo,
    };
  }

  /// ✅ FACTORY simplificado con BaseModel
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map.getOrDefault('id', ''),
      nombre: map.getOrDefault('nombre', ''),
      descripcion: map.getOrDefault('descripcion', ''),
      codigoInvitacion: map.getOrDefault('codigoInvitacion', ''),
      presidenteId: map.getOrDefault('presidenteId', ''),
      miembrosIds: BaseModel.parseStringList(map['miembrosIds']),
      totalAhorros: BaseModel.parseDouble(map['totalAhorros']),
      totalPrestamos: BaseModel.parseDouble(map['totalPrestamos']),
      fechaCreacion: BaseModel.parseDate(map['fechaCreacion']),
      esActivo: map.getOrDefault('esActivo', true),
    );
  }

  // ==================== COPYWITH ====================

  GroupModel copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? codigoInvitacion,
    String? presidenteId,
    List<String>? miembrosIds,
    double? totalAhorros,
    double? totalPrestamos,
    DateTime? fechaCreacion,
    bool? esActivo,
  }) {
    return GroupModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      codigoInvitacion: codigoInvitacion ?? this.codigoInvitacion,
      presidenteId: presidenteId ?? this.presidenteId,
      miembrosIds: miembrosIds ?? this.miembrosIds,
      totalAhorros: totalAhorros ?? this.totalAhorros,
      totalPrestamos: totalPrestamos ?? this.totalPrestamos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      esActivo: esActivo ?? this.esActivo,
    );
  }

  // ==================== GETTERS ÚTILES ====================

  /// Número de miembros
  int get numeroMiembros => miembrosIds.length;

  /// Verifica si un usuario es presidente
  bool esPresidente(String userId) => presidenteId == userId;

  /// Verifica si un usuario es miembro
  bool esMiembro(String userId) => miembrosIds.contains(userId);

  /// Total en caja (ahorros - préstamos)
  double get totalEnCaja => totalAhorros - totalPrestamos;

  /// Días desde la creación
  int get diasDesdeCreacion {
    return DateTime.now().difference(fechaCreacion).inDays;
  }

  /// Grupo es nuevo (menos de 30 días)
  bool get esGrupoNuevo => diasDesdeCreacion < 30;

  /// Promedio de ahorros por miembro
  double get promedioAhorrosPorMiembro {
    if (numeroMiembros == 0) return 0.0;
    return totalAhorros / numeroMiembros;
  }

  // ==================== VALIDACIONES ====================

  /// Valida si el código de invitación es válido
  bool get codigoValido {
    return codigoInvitacion.length == 6 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(codigoInvitacion);
  }

  /// Valida si el grupo tiene miembros
  bool get tieneMiembros => miembrosIds.isNotEmpty;

  /// Valida si el grupo está activo y tiene miembros
  bool get esOperacional => esActivo && tieneMiembros;

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupModel(id: $id, nombre: $nombre, miembros: $numeroMiembros)';
  }
}
