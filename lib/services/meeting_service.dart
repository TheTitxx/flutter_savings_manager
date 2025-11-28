import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import 'core/service_result.dart';
import 'core/firebase_collections.dart';

/// Servicio especializado en gestión de reuniones
///
/// Responsabilidades:
/// - Crear y programar reuniones
/// - Gestionar asistencia
/// - Notificaciones a miembros
/// - Iniciar/finalizar reuniones
class MeetingService {
  final FirebaseFirestore _firestore;

  MeetingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== CREAR REUNIONES ====================

  /// Crea una referencia para una nueva reunión (ID generado por Firestore)
  DocumentReference createMeetingRef() {
    return _firestore.collection(FirebaseCollections.meetings).doc();
  }

  /// Crea una nueva reunión y notifica a los miembros
  ///
  /// Proceso:
  /// 1. Guarda la reunión en Firestore
  /// 2. Obtiene el grupo para notificar miembros
  /// 3. Crea notificaciones para cada miembro (excepto creador)
  Future<ServiceResult<MeetingModel>> createMeeting(
    MeetingModel meeting,
  ) async {
    try {
      debugPrint('📅 Creando reunión: ${meeting.titulo}');

      // 1. Guardar reunión
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meeting.id)
          .set(meeting.toMap());

      debugPrint('✅ Reunión guardada en Firestore');

      // 2. Obtener grupo para notificar miembros
      final groupDoc = await _firestore
          .collection(FirebaseCollections.groups)
          .doc(meeting.grupoId)
          .get();

      if (!groupDoc.exists) {
        debugPrint('⚠️ Grupo no encontrado - No se enviarán notificaciones');
        return ServiceResult.success(meeting);
      }

      final miembrosIds = List<String>.from(
        groupDoc.data()!['miembrosIds'] ?? [],
      );

      // 3. Crear notificaciones para cada miembro (excepto creador)
      int notificacionesEnviadas = 0;
      for (final memberId in miembrosIds) {
        if (memberId != meeting.creadoPorId) {
          try {
            await _firestore.collection(FirebaseCollections.notifications).add({
              'usuarioId': memberId,
              'tipo': 'nueva_reunion',
              'titulo': '📅 Nueva Reunión Programada',
              'mensaje':
                  '${meeting.creadoPorNombre} programó: ${meeting.titulo}',
              'reunionId': meeting.id,
              'grupoId': meeting.grupoId,
              'fechaHora': Timestamp.fromDate(meeting.fechaHora),
              'leida': false,
              'fechaCreacion': FieldValue.serverTimestamp(),
            });

            notificacionesEnviadas++;
          } catch (e) {
            debugPrint('⚠️ Error al notificar a $memberId: $e');
          }
        }
      }

      debugPrint(
        '✅ Reunión creada - $notificacionesEnviadas notificaciones enviadas',
      );
      return ServiceResult.success(meeting);
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.meetingCreateFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== CONSULTAR REUNIONES ====================

  /// Obtiene snapshot de reuniones de un grupo (lectura única)
  Future<QuerySnapshot> getGroupMeetingsSnapshot(String groupId) {
    return _firestore
        .collection(FirebaseCollections.meetings)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .get();
  }

  /// Stream de todas las reuniones de un grupo (ordenadas por fecha)
  Stream<List<MeetingModel>> getGroupMeetings(String groupId) {
    return _firestore
        .collection(FirebaseCollections.meetings)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .orderBy(FirebaseFields.fechaHora, descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return MeetingModel.fromMap(doc.data());
                } catch (e) {
                  debugPrint('⚠️ Error al parsear reunión ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<MeetingModel>()
              .toList();
        });
  }

  /// Stream de reuniones activas (futuras) de un grupo
  Stream<List<MeetingModel>> getActiveMeetings(String groupId) {
    final now = DateTime.now();

    return _firestore
        .collection(FirebaseCollections.meetings)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .where(FirebaseFields.activa, isEqualTo: true)
        .where(FirebaseFields.fechaHora, isGreaterThan: Timestamp.fromDate(now))
        .orderBy(FirebaseFields.fechaHora, descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return MeetingModel.fromMap(doc.data());
                } catch (e) {
                  debugPrint(
                    '⚠️ Error al parsear reunión activa ${doc.id}: $e',
                  );
                  return null;
                }
              })
              .whereType<MeetingModel>()
              .toList();
        });
  }

  /// Obtiene una reunión específica por su ID
  Future<ServiceResult<MeetingModel>> getMeetingById(String meetingId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .get();

      if (!doc.exists) {
        return ServiceResult.failure(ErrorMessages.meetingNotFound);
      }

      final meeting = MeetingModel.fromMap(doc.data()!);
      return ServiceResult.success(meeting);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener reunión',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Obtiene reuniones de hoy para un grupo
  Future<ServiceResult<List<MeetingModel>>> getTodayMeetings(
    String groupId,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(FirebaseCollections.meetings)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.activa, isEqualTo: true)
          .where(
            FirebaseFields.fechaHora,
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            FirebaseFields.fechaHora,
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .orderBy(FirebaseFields.fechaHora, descending: false)
          .get();

      final meetings = snapshot.docs
          .map((doc) {
            try {
              return MeetingModel.fromMap(doc.data());
            } catch (e) {
              return null;
            }
          })
          .whereType<MeetingModel>()
          .toList();

      return ServiceResult.success(meetings);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener reuniones de hoy',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== GESTIÓN DE REUNIONES ====================

  /// Marca una reunión como vista por un usuario
  Future<ServiceResult<void>> markMeetingAsViewed(
    String meetingId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .update({
            FirebaseFields.miembrosNotificados: FieldValue.arrayUnion([userId]),
          });

      debugPrint('✅ Reunión $meetingId marcada como vista para: $userId');
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al marcar reunión como vista',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Cancela una reunión y notifica a los miembros
  Future<ServiceResult<void>> cancelMeeting(String meetingId) async {
    try {
      debugPrint('🔴 Cancelando reunión: $meetingId');

      // 1. Obtener datos de la reunión
      final meetingDoc = await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .get();

      if (!meetingDoc.exists) {
        return ServiceResult.failure(ErrorMessages.meetingNotFound);
      }

      final meeting = MeetingModel.fromMap(meetingDoc.data()!);

      // 2. Actualizar reunión como inactiva
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .update({FirebaseFields.activa: false});

      debugPrint('✅ Reunión marcada como inactiva');

      // 3. Obtener grupo para notificar a miembros
      final groupDoc = await _firestore
          .collection(FirebaseCollections.groups)
          .doc(meeting.grupoId)
          .get();

      if (groupDoc.exists) {
        final miembrosIds = List<String>.from(
          groupDoc.data()!['miembrosIds'] ?? [],
        );
        int notificacionesEnviadas = 0;

        // 4. Notificar a cada miembro sobre cancelación
        for (final memberId in miembrosIds) {
          if (memberId != meeting.creadoPorId) {
            try {
              await _firestore
                  .collection(FirebaseCollections.notifications)
                  .add({
                    'usuarioId': memberId,
                    'tipo': 'reunion_cancelada',
                    'titulo': '❌ Reunión Cancelada',
                    'mensaje':
                        '${meeting.creadoPorNombre} canceló: ${meeting.titulo}',
                    'reunionId': meeting.id,
                    'grupoId': meeting.grupoId,
                    'fechaOriginal': Timestamp.fromDate(meeting.fechaHora),
                    'leida': false,
                    'fechaCreacion': FieldValue.serverTimestamp(),
                  });

              notificacionesEnviadas++;
            } catch (e) {
              debugPrint('⚠️ Error al notificar cancelación a $memberId: $e');
            }
          }
        }

        debugPrint(
          '✅ Reunión cancelada - $notificacionesEnviadas notificaciones enviadas',
        );
      }

      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.meetingCancelFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Inicia una reunión (marca hora de inicio)
  Future<ServiceResult<void>> iniciarReunion(String meetingId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .update({FirebaseFields.horaInicio: FieldValue.serverTimestamp()});

      debugPrint('✅ Reunión iniciada: $meetingId');
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al iniciar reunión',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Finaliza una reunión (marca hora de fin)
  Future<ServiceResult<void>> finalizarReunion(String meetingId) async {
    try {
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .update({
            FirebaseFields.horaFin: FieldValue.serverTimestamp(),
            FirebaseFields.finalizada: true,
          });

      debugPrint('✅ Reunión finalizada: $meetingId');
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al finalizar reunión',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Actualiza información de una reunión
  Future<ServiceResult<void>> updateMeeting(MeetingModel meeting) async {
    try {
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meeting.id)
          .update(meeting.toMap());

      debugPrint('✅ Reunión actualizada: ${meeting.id}');
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al actualizar reunión',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== ASISTENCIA ====================

  /// Marca la asistencia de un usuario a una reunión
  Future<ServiceResult<void>> marcarAsistencia(
    String meetingId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .update({
            FirebaseFields.asistentes: FieldValue.arrayUnion([userId]),
          });

      debugPrint('✅ Asistencia marcada: $userId en reunión $meetingId');
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al marcar asistencia',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Quita la asistencia de un usuario (por error)
  Future<ServiceResult<void>> quitarAsistencia(
    String meetingId,
    String userId,
  ) async {
    try {
      await _firestore
          .collection(FirebaseCollections.meetings)
          .doc(meetingId)
          .update({
            FirebaseFields.asistentes: FieldValue.arrayRemove([userId]),
          });

      debugPrint('✅ Asistencia removida: $userId de reunión $meetingId');
      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al quitar asistencia',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtiene el número de reuniones no vistas por un usuario
  Future<ServiceResult<int>> getUnviewedMeetingsCount(
    String groupId,
    String userId,
  ) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection(FirebaseCollections.meetings)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.activa, isEqualTo: true)
          .where(
            FirebaseFields.fechaHora,
            isGreaterThan: Timestamp.fromDate(now),
          )
          .get();

      int count = 0;

      for (final doc in snapshot.docs) {
        final meeting = MeetingModel.fromMap(doc.data());

        if (!meeting.usuarioNotificado(userId)) {
          count++;
        }
      }

      debugPrint('📊 Reuniones no vistas: $count');
      return ServiceResult.success(count);
    } catch (e) {
      return ServiceResult.failure(
        'Error al contar reuniones no vistas',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
