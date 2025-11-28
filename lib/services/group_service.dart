import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import 'core/service_result.dart';
import 'core/firebase_collections.dart';

/// Servicio especializado en gestión de grupos
///
/// Responsabilidades:
/// - Creación de grupos
/// - Unión a grupos mediante código
/// - Gestión de miembros
/// - Obtención de información de grupos
class GroupService {
  final FirebaseFirestore _firestore;
  final String? Function() _getCurrentUserId;

  GroupService({
    FirebaseFirestore? firestore,
    required String? Function() getCurrentUserId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _getCurrentUserId = getCurrentUserId;

  // ==================== CREACIÓN DE GRUPOS ====================

  /// Crea un nuevo grupo con el usuario actual como presidente
  ///
  /// Genera automáticamente:
  /// - ID único del grupo
  /// - Código de invitación de 6 caracteres
  ///
  /// El creador se añade automáticamente como primer miembro
  Future<ServiceResult<GroupModel>> createGroup({
    required String nombre,
    required String descripcion,
  }) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      return ServiceResult.failure(ErrorMessages.authNoUser);
    }

    try {
      // Generar ID y código único
      final groupId = _firestore
          .collection(FirebaseCollections.groups)
          .doc()
          .id;
      final codigoInvitacion = _generateInvitationCode();

      final newGroup = GroupModel(
        id: groupId,
        nombre: nombre,
        descripcion: descripcion,
        codigoInvitacion: codigoInvitacion,
        presidenteId: currentUserId,
        miembrosIds: [currentUserId],
        fechaCreacion: DateTime.now().toUtc(),
      );

      await _firestore
          .collection(FirebaseCollections.groups)
          .doc(groupId)
          .set(newGroup.toMap());

      return ServiceResult.success(newGroup);
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.groupCreateFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== UNIRSE A GRUPOS ====================

  /// Une al usuario actual a un grupo mediante código de invitación
  ///
  /// Valida que:
  /// - El código exista
  /// - El usuario no sea ya miembro
  Future<ServiceResult<GroupModel>> joinGroup(String codigoInvitacion) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      return ServiceResult.failure(ErrorMessages.authNoUser);
    }

    try {
      // Buscar grupo por código (case-insensitive)
      final query = await _firestore
          .collection(FirebaseCollections.groups)
          .where(
            FirebaseFields.codigoInvitacion,
            isEqualTo: codigoInvitacion.toUpperCase(),
          )
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return ServiceResult.failure(ErrorMessages.groupInvalidCode);
      }

      final groupDoc = query.docs.first;
      final group = GroupModel.fromMap(groupDoc.data());

      // Verificar si ya es miembro
      if (group.miembrosIds.contains(currentUserId)) {
        return ServiceResult.failure('Ya eres miembro de este grupo');
      }

      // Agregar usuario al grupo
      await _firestore
          .collection(FirebaseCollections.groups)
          .doc(group.id)
          .update({
            FirebaseFields.miembrosIds: FieldValue.arrayUnion([currentUserId]),
          });

      // Retornar grupo actualizado
      final updatedGroup = group.copyWith(
        miembrosIds: [...group.miembrosIds, currentUserId],
      );

      return ServiceResult.success(updatedGroup);
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.groupJoinFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== OBTENER GRUPOS ====================

  /// Obtiene un grupo específico por su ID
  Future<ServiceResult<GroupModel>> getGroup(String groupId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.groups)
          .doc(groupId)
          .get();

      if (!doc.exists) {
        return ServiceResult.failure(ErrorMessages.groupNotFound);
      }

      final group = GroupModel.fromMap(doc.data()!);
      return ServiceResult.success(group);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener grupo',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Stream de los grupos del usuario actual
  ///
  /// Se actualiza en tiempo real cuando:
  /// - Se crea un nuevo grupo
  /// - Se une a un grupo
  /// - Se modifica un grupo
  Stream<List<GroupModel>> getUserGroups() {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirebaseCollections.groups)
        .where(FirebaseFields.miembrosIds, arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return GroupModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<GroupModel>()
              .toList();
        });
  }

  // ==================== GESTIÓN DE MIEMBROS ====================

  /// Elimina un miembro del grupo
  ///
  /// Solo el presidente puede eliminar miembros
  /// No se puede eliminar al presidente
  Future<ServiceResult<void>> removeMember(
    String groupId,
    String userId,
  ) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      return ServiceResult.failure(ErrorMessages.authNoUser);
    }

    try {
      // Verificar permisos
      final groupResult = await getGroup(groupId);
      if (groupResult.isFailure) {
        return ServiceResult.failure(groupResult.errorMessage!);
      }
      final group = groupResult.data!;

      if (group.presidenteId != currentUserId) {
        return ServiceResult.failure(
          'Solo el presidente puede eliminar miembros',
        );
      }

      if (group.presidenteId == userId) {
        return ServiceResult.failure('No puedes eliminar al presidente');
      }

      // Eliminar del array
      await _firestore
          .collection(FirebaseCollections.groups)
          .doc(groupId)
          .update({
            FirebaseFields.miembrosIds: FieldValue.arrayRemove([userId]),
          });

      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al eliminar miembro',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Genera un código de invitación aleatorio de 6 caracteres
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
