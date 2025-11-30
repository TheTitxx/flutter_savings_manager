import '../core/models/base_model.dart';

// ==================== ENUMS ====================

/// Estados de una solicitud de préstamo
enum EstadoSolicitud {
  pendiente,
  aprobada,
  rechazada,
  completada;

  /// ✅ Nombre legible
  String get nombre {
    switch (this) {
      case EstadoSolicitud.pendiente:
        return 'Pendiente';
      case EstadoSolicitud.aprobada:
        return 'Aprobada';
      case EstadoSolicitud.rechazada:
        return 'Rechazada';
      case EstadoSolicitud.completada:
        return 'Completada';
    }
  }
}

// ==================== VOTO ====================

/// ✅ Voto individual optimizado
class Voto extends BaseModel {
  final String userId;
  final String nombreUsuario;
  final bool aprobo;
  final DateTime fechaVoto;

  Voto({
    required this.userId,
    required this.nombreUsuario,
    required this.aprobo,
    required this.fechaVoto,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombreUsuario': nombreUsuario,
      'aprobo': aprobo,
      'fechaVoto': fechaVoto.toIso8601String(),
    };
  }

  factory Voto.fromMap(Map<String, dynamic> map) {
    return Voto(
      userId: map.getOrDefault('userId', ''),
      nombreUsuario: map.getOrDefault('nombreUsuario', ''),
      aprobo: map.getOrDefault('aprobo', false),
      fechaVoto: BaseModel.parseDate(map['fechaVoto']),
    );
  }

  @override
  String toString() => 'Voto($nombreUsuario: ${aprobo ? "SÍ" : "NO"})';
}

// ==================== LOAN REQUEST ====================

/// ✅ LOAN REQUEST MODEL OPTIMIZADO
class LoanRequestModel extends BaseModel {
  final String id;
  final String grupoId;
  final String solicitanteId;
  final String nombreSolicitante;
  final double montoSolicitado;
  final int plazoCuotas;
  final double tasaInteres;
  final String motivo;
  final DateTime fechaSolicitud;
  final EstadoSolicitud estado;
  final List<Voto> votos;
  final DateTime? fechaAprobacion;
  final double montoPagado;

  LoanRequestModel({
    required this.id,
    required this.grupoId,
    required this.solicitanteId,
    required this.nombreSolicitante,
    required this.montoSolicitado,
    required this.plazoCuotas,
    this.tasaInteres = 12.0,
    required this.motivo,
    required this.fechaSolicitud,
    this.estado = EstadoSolicitud.pendiente,
    this.votos = const [],
    this.fechaAprobacion,
    this.montoPagado = 0.0,
  });

  // ==================== SERIALIZACIÓN ====================

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grupoId': grupoId,
      'solicitanteId': solicitanteId,
      'nombreSolicitante': nombreSolicitante,
      'montoSolicitado': montoSolicitado,
      'plazoCuotas': plazoCuotas,
      'tasaInteres': tasaInteres,
      'motivo': motivo,
      'fechaSolicitud': fechaSolicitud.toIso8601String(),
      'estado': estado.name, // ✅ Usar .name
      'votos': votos.map((v) => v.toMap()).toList(),
      'fechaAprobacion': fechaAprobacion?.toIso8601String(),
      'montoPagado': montoPagado,
    };
  }

  /// ✅ FACTORY simplificado
  factory LoanRequestModel.fromMap(Map<String, dynamic> map) {
    return LoanRequestModel(
      id: map.getOrDefault('id', ''),
      grupoId: map.getOrDefault('grupoId', ''),
      solicitanteId: map.getOrDefault('solicitanteId', ''),
      nombreSolicitante: map.getOrDefault('nombreSolicitante', ''),
      montoSolicitado: BaseModel.parseDouble(map['montoSolicitado']),
      plazoCuotas: BaseModel.parseInt(map['plazoCuotas'], defaultValue: 12),
      tasaInteres: BaseModel.parseDouble(map['tasaInteres'], defaultValue: 5.0),
      motivo: map.getOrDefault('motivo', ''),
      fechaSolicitud: BaseModel.parseDate(map['fechaSolicitud']),
      estado: _parseEstado(map['estado']),
      votos: _parseVotos(map['votos']),
      fechaAprobacion: map['fechaAprobacion'] != null
          ? BaseModel.parseDate(map['fechaAprobacion'])
          : null,
      montoPagado: BaseModel.parseDouble(map['montoPagado']),
    );
  }

  /// ✅ Parser de estado seguro
  static EstadoSolicitud _parseEstado(dynamic value) {
    if (value == null) return EstadoSolicitud.pendiente;

    final stringValue = value.toString();

    try {
      return EstadoSolicitud.values.firstWhere(
        (e) => e.name == stringValue,
        orElse: () => EstadoSolicitud.pendiente,
      );
    } catch (e) {
      return EstadoSolicitud.pendiente;
    }
  }

  /// ✅ Parser de votos seguro
  static List<Voto> _parseVotos(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .map((v) {
          try {
            return Voto.fromMap(v as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<Voto>()
        .toList();
  }

  // ==================== COPYWITH ====================

  LoanRequestModel copyWith({
    String? id,
    String? grupoId,
    String? solicitanteId,
    String? nombreSolicitante,
    double? montoSolicitado,
    int? plazoCuotas,
    double? tasaInteres,
    String? motivo,
    DateTime? fechaSolicitud,
    EstadoSolicitud? estado,
    List<Voto>? votos,
    DateTime? fechaAprobacion,
    double? montoPagado,
  }) {
    return LoanRequestModel(
      id: id ?? this.id,
      grupoId: grupoId ?? this.grupoId,
      solicitanteId: solicitanteId ?? this.solicitanteId,
      nombreSolicitante: nombreSolicitante ?? this.nombreSolicitante,
      montoSolicitado: montoSolicitado ?? this.montoSolicitado,
      plazoCuotas: plazoCuotas ?? this.plazoCuotas,
      tasaInteres: tasaInteres ?? this.tasaInteres,
      motivo: motivo ?? this.motivo,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      estado: estado ?? this.estado,
      votos: votos ?? this.votos,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      montoPagado: montoPagado ?? this.montoPagado,
    );
  }

  // ==================== GETTERS DE VOTOS ====================

  /// Total de votos a favor
  int get votosAFavor => votos.where((v) => v.aprobo).length;

  /// Total de votos en contra
  int get votosEnContra => votos.where((v) => !v.aprobo).length;

  /// Total de votos realizados
  int get totalVotos => votos.length;

  /// Verifica si un usuario ya votó
  bool usuarioYaVoto(String userId) => votos.any((v) => v.userId == userId);

  // ==================== GETTERS FINANCIEROS ====================

  /// Monto total a pagar (con interés)
  double get montoTotalConInteres {
    return montoSolicitado * (1 + (tasaInteres / 100));
  }

  /// Monto por cuota
  double get montoPorCuota => montoTotalConInteres / plazoCuotas;

  /// Saldo pendiente
  double get saldoPendiente => montoTotalConInteres - montoPagado;

  /// Porcentaje pagado
  double get porcentajePagado {
    if (montoTotalConInteres == 0) return 0;
    return (montoPagado / montoTotalConInteres) * 100;
  }

  /// Cuotas pagadas (estimado)
  int get cuotasPagadas => (montoPagado / montoPorCuota).floor();

  /// Cuotas pendientes
  int get cuotasPendientes => plazoCuotas - cuotasPagadas;

  /// Verifica si está completamente pagado
  bool get estaPagado => montoPagado >= montoTotalConInteres;

  // ==================== LÓGICA DE VOTACIÓN ====================

  /// Verifica si todos votaron (excepto el solicitante)
  bool todosVotaron(int totalMiembros) {
    int miembrosQueDebenVotar = totalMiembros - 1;
    return totalVotos >= miembrosQueDebenVotar;
  }

  /// Verifica si pasaron 3 días
  bool pasaronTresDias() {
    final diferencia = DateTime.now().difference(fechaSolicitud);
    return diferencia.inDays >= 3;
  }

  /// Días restantes para votar
  int diasRestantes() {
    final diferencia = DateTime.now().difference(fechaSolicitud);
    final diasPasados = diferencia.inDays;
    return 3 - diasPasados > 0 ? 3 - diasPasados : 0;
  }

  /// Determinar el resultado por mayoría simple
  bool aprobarPorMayoria() => votosAFavor > votosEnContra;

  /// Verifica si la votación debe cerrarse automáticamente
  String? verificarCierrAutomatico(int totalMiembros) {
    // Solo procesar si está pendiente
    if (estado != EstadoSolicitud.pendiente) return null;

    // Caso 1: Todos votaron (excepto el solicitante)
    if (todosVotaron(totalMiembros)) {
      return aprobarPorMayoria() ? 'aprobada' : 'rechazada';
    }

    // Caso 2: Pasaron 3 días
    if (pasaronTresDias() && totalVotos > 0) {
      return aprobarPorMayoria() ? 'aprobada' : 'rechazada';
    }

    return null; // Sigue pendiente
  }

  // ==================== VALIDACIONES ====================

  /// Valida si el préstamo está activo
  bool get estaActivo => estado == EstadoSolicitud.aprobada && !estaPagado;

  /// Valida si está en proceso de votación
  bool get enVotacion => estado == EstadoSolicitud.pendiente;

  /// Valida si fue rechazado
  bool get fueRechazado => estado == EstadoSolicitud.rechazada;

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoanRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LoanRequestModel(id: $id, monto: $montoSolicitado, estado: ${estado.nombre})';
  }
}
