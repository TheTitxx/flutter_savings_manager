import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/base_model.dart';

/// ✅ MEETING MODEL OPTIMIZADO
class MeetingModel extends BaseModel {
  final String id;
  final String grupoId;
  final String titulo;
  final String? descripcion;
  final DateTime fechaHora;
  final String creadoPorId;
  final String creadoPorNombre;
  final DateTime fechaCreacion;
  final bool activa;
  final List<String> miembrosNotificados;
  final List<String> asistentes;
  final DateTime? horaInicio;
  final DateTime? horaFin;
  final bool finalizada;

  MeetingModel({
    required this.id,
    required this.grupoId,
    required this.titulo,
    this.descripcion,
    required this.fechaHora,
    required this.creadoPorId,
    required this.creadoPorNombre,
    required this.fechaCreacion,
    this.activa = true,
    this.miembrosNotificados = const [],
    this.asistentes = const [],
    this.horaInicio,
    this.horaFin,
    this.finalizada = false,
  });

  // ==================== SERIALIZACIÓN ====================

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grupoId': grupoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'creadoPorId': creadoPorId,
      'creadoPorNombre': creadoPorNombre,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'activa': activa,
      'miembrosNotificados': miembrosNotificados,
      'asistentes': asistentes,
      'horaInicio': horaInicio != null ? Timestamp.fromDate(horaInicio!) : null,
      'horaFin': horaFin != null ? Timestamp.fromDate(horaFin!) : null,
      'finalizada': finalizada,
    };
  }

  /// ✅ FACTORY simplificado con BaseModel
  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map.getOrDefault('id', ''),
      grupoId: map.getOrDefault('grupoId', ''),
      titulo: map.getOrDefault('titulo', ''),
      descripcion: map['descripcion'],
      fechaHora: BaseModel.parseDate(map['fechaHora']),
      creadoPorId: map.getOrDefault('creadoPorId', ''),
      creadoPorNombre: map.getOrDefault('creadoPorNombre', ''),
      fechaCreacion: BaseModel.parseDate(map['fechaCreacion']),
      activa: map.getOrDefault('activa', true),
      miembrosNotificados: BaseModel.parseStringList(
        map['miembrosNotificados'],
      ),
      asistentes: BaseModel.parseStringList(map['asistentes']),
      horaInicio: map['horaInicio'] != null
          ? BaseModel.parseDate(map['horaInicio'])
          : null,
      horaFin: map['horaFin'] != null
          ? BaseModel.parseDate(map['horaFin'])
          : null,
      finalizada: map.getOrDefault('finalizada', false),
    );
  }

  // ==================== COPYWITH ====================

  MeetingModel copyWith({
    String? id,
    String? grupoId,
    String? titulo,
    String? descripcion,
    DateTime? fechaHora,
    String? creadoPorId,
    String? creadoPorNombre,
    DateTime? fechaCreacion,
    bool? activa,
    List<String>? miembrosNotificados,
    List<String>? asistentes,
    DateTime? horaInicio,
    DateTime? horaFin,
    bool? finalizada,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      grupoId: grupoId ?? this.grupoId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaHora: fechaHora ?? this.fechaHora,
      creadoPorId: creadoPorId ?? this.creadoPorId,
      creadoPorNombre: creadoPorNombre ?? this.creadoPorNombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activa: activa ?? this.activa,
      miembrosNotificados: miembrosNotificados ?? this.miembrosNotificados,
      asistentes: asistentes ?? this.asistentes,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      finalizada: finalizada ?? this.finalizada,
    );
  }

  // ==================== GETTERS TEMPORALES ====================

  /// Ya pasó la hora programada
  bool get yaPaso => DateTime.now().isAfter(fechaHora);

  /// Es hoy
  bool get esHoy {
    final now = DateTime.now();
    return fechaHora.year == now.year &&
        fechaHora.month == now.month &&
        fechaHora.day == now.day;
  }

  /// Es próxima (dentro de 7 días)
  bool get esProxima {
    final now = DateTime.now();
    final diferencia = fechaHora.difference(now);
    return !diferencia.isNegative && diferencia.inHours <= 168;
  }

  /// Es nueva (creada hace menos de 24 horas)
  bool get esNueva {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaCreacion);
    return diferencia.inHours < 24;
  }

  /// Puede iniciar (dentro de 15 min antes o hasta 2 horas después)
  bool get puedeIniciar {
    final now = DateTime.now();
    final diferencia = fechaHora.difference(now);
    return diferencia.inMinutes <= 15 && diferencia.inMinutes >= -120;
  }

  /// Puede marcar asistencia (ya inició pero no ha finalizado)
  bool get puedeMarcarAsistencia {
    return horaInicio != null && horaFin == null;
  }

  // ==================== GETTERS DE ESTADO ====================

  /// Estado de la reunión
  String get estado {
    if (finalizada) return 'Finalizada';
    if (!activa) return 'Cancelada';
    if (horaInicio != null && horaFin == null) return 'En curso';
    if (yaPaso && horaInicio == null) return 'No iniciada';
    return 'Programada';
  }

  /// Duración de la reunión
  Duration? get duracion {
    if (horaInicio != null && horaFin != null) {
      return horaFin!.difference(horaInicio!);
    }
    return null;
  }

  /// Número de asistentes
  int get numeroAsistentes => asistentes.length;

  /// Número de notificados
  int get numeroNotificados => miembrosNotificados.length;

  /// Porcentaje de asistencia (requiere total de miembros)
  double calcularPorcentajeAsistencia(int totalMiembros) {
    if (totalMiembros == 0) return 0;
    return (numeroAsistentes / totalMiembros) * 100;
  }

  // ==================== VALIDACIONES ====================

  /// Usuario fue notificado
  bool usuarioNotificado(String userId) {
    return miembrosNotificados.contains(userId);
  }

  /// Usuario asistió
  bool usuarioAsistio(String userId) {
    return asistentes.contains(userId);
  }

  /// Tiene descripción
  bool get tieneDescripcion => descripcion != null && descripcion!.isNotEmpty;

  /// Está en progreso
  bool get enProgreso => horaInicio != null && horaFin == null && !finalizada;

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeetingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MeetingModel(id: $id, titulo: $titulo, estado: $estado)';
  }
}
