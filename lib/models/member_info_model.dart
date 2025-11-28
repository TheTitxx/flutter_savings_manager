import 'user_model.dart';

/// ✅ MEMBER INFO MODEL OPTIMIZADO
///
/// Combina información del usuario con sus estadísticas en el grupo
class MemberInfo {
  final UserModel user;
  final double totalAhorros;
  final double totalRetiros;
  final double prestamosActivos;
  final int numeroTransacciones;
  final DateTime fechaIngreso;
  final bool esPresidente;

  MemberInfo({
    required this.user,
    this.totalAhorros = 0.0,
    this.totalRetiros = 0.0,
    this.prestamosActivos = 0.0,
    this.numeroTransacciones = 0,
    required this.fechaIngreso,
    this.esPresidente = false,
  });

  // ==================== GETTERS FINANCIEROS ====================

  /// Saldo neto del miembro
  double get saldoNeto => totalAhorros - totalRetiros;

  /// Total en el grupo (ahorros + préstamos activos)
  double get totalEnGrupo => totalAhorros + prestamosActivos;

  /// Promedio por transacción
  double get promedioPorTransaccion {
    if (numeroTransacciones == 0) return 0;
    return totalAhorros / numeroTransacciones;
  }

  /// Contribución porcentual al grupo
  double calcularPorcentajeAporte(double totalGrupo) {
    if (totalGrupo == 0) return 0.0;
    return (totalAhorros / totalGrupo) * 100;
  }

  // ==================== GETTERS DE ESTADO ====================

  /// Días como miembro
  int get diasComoMiembro {
    return DateTime.now().difference(fechaIngreso).inDays;
  }

  /// Es miembro nuevo (menos de 30 días)
  bool get esMiembroNuevo => diasComoMiembro < 30;

  /// Tiene préstamos activos
  bool get tienePrestamosActivos => prestamosActivos > 0;

  /// Es ahorrista activo (más de 5 transacciones)
  bool get esAhorristaActivo => numeroTransacciones >= 5;

  /// Nivel de participación (0-3)
  /// 0: Inactivo, 1: Bajo, 2: Medio, 3: Alto
  int get nivelParticipacion {
    if (numeroTransacciones == 0) return 0;
    if (numeroTransacciones < 5) return 1;
    if (numeroTransacciones < 15) return 2;
    return 3;
  }

  /// Descripción del nivel de participación
  String get nivelParticipacionTexto {
    switch (nivelParticipacion) {
      case 0:
        return 'Sin actividad';
      case 1:
        return 'Participación baja';
      case 2:
        return 'Participación media';
      case 3:
        return 'Participación alta';
      default:
        return 'Desconocido';
    }
  }

  // ==================== VALIDACIONES ====================

  /// Puede retirar (tiene saldo positivo)
  bool get puedeRetirar => saldoNeto > 0;

  /// Está al día (no tiene préstamos o los paga)
  bool get estaAlDia => prestamosActivos == 0 || numeroTransacciones > 0;

  // ==================== COMPARACIÓN ====================

  /// Comparar por total de ahorros (para ordenar)
  static int compararPorAhorros(MemberInfo a, MemberInfo b) {
    return b.totalAhorros.compareTo(a.totalAhorros);
  }

  /// Comparar por participación (para ordenar)
  static int compararPorParticipacion(MemberInfo a, MemberInfo b) {
    return b.numeroTransacciones.compareTo(a.numeroTransacciones);
  }

  /// Comparar por antigüedad (para ordenar)
  static int compararPorAntiguedad(MemberInfo a, MemberInfo b) {
    return a.fechaIngreso.compareTo(b.fechaIngreso);
  }

  // ==================== COPYWITH ====================

  MemberInfo copyWith({
    UserModel? user,
    double? totalAhorros,
    double? totalRetiros,
    double? prestamosActivos,
    int? numeroTransacciones,
    DateTime? fechaIngreso,
    bool? esPresidente,
  }) {
    return MemberInfo(
      user: user ?? this.user,
      totalAhorros: totalAhorros ?? this.totalAhorros,
      totalRetiros: totalRetiros ?? this.totalRetiros,
      prestamosActivos: prestamosActivos ?? this.prestamosActivos,
      numeroTransacciones: numeroTransacciones ?? this.numeroTransacciones,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      esPresidente: esPresidente ?? this.esPresidente,
    );
  }

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberInfo && other.user.uid == user.uid;
  }

  @override
  int get hashCode => user.uid.hashCode;

  @override
  String toString() {
    return 'MemberInfo(user: ${user.nombre}, ahorros: $totalAhorros, transacciones: $numeroTransacciones)';
  }
}
