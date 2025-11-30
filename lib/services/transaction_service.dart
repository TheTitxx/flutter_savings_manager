import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'core/service_result.dart';
import 'core/firebase_collections.dart';

/// Servicio especializado en transacciones (ahorros, retiros, etc.)
///
/// Responsabilidades:
/// - Crear transacciones de ahorro/retiro
/// - Actualizar totales del grupo
/// - Obtener historial de transacciones
/// - Calcular estadísticas
class TransactionService {
  final FirebaseFirestore _firestore;

  TransactionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== CREAR TRANSACCIONES ====================

  /// Crea una nueva transacción (ahorro, retiro, interés, etc.)
  ///
  /// Actualiza automáticamente los totales del grupo:
  /// - Ahorros: suma al totalAhorros
  /// - Retiros: resta del totalAhorros
  /// - Préstamos: suma al totalPrestamos
  Future<ServiceResult<TransactionModel>> createTransaction(
    TransactionModel transaction,
  ) async {
    try {
      // 1. Guardar transacción
      await _firestore
          .collection(FirebaseCollections.transactions)
          .doc(transaction.id)
          .set(transaction.toMap());

      // 2. Actualizar totales del grupo
      await _updateGroupTotals(transaction);

      return ServiceResult.success(transaction);
    } catch (e) {
      return ServiceResult.failure(
        ErrorMessages.transactionCreateFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Actualiza los totales del grupo según el tipo de transacción
  Future<void> _updateGroupTotals(TransactionModel transaction) async {
    final groupRef = _firestore
        .collection(FirebaseCollections.groups)
        .doc(transaction.grupoId);

    if (transaction.esIngreso()) {
      // Ahorro, pago de préstamo, interés, utilidad
      await groupRef.update({
        FirebaseFields.totalAhorros: FieldValue.increment(transaction.monto),
      });
    } else {
      // Retiro o préstamo
      if (transaction.tipo == TipoTransaccion.retiro) {
        await groupRef.update({
          FirebaseFields.totalAhorros: FieldValue.increment(-transaction.monto),
        });
      } else if (transaction.tipo == TipoTransaccion.prestamo) {
        await groupRef.update({
          FirebaseFields.totalPrestamos: FieldValue.increment(
            transaction.monto,
          ),
        });
      }
    }
  }

  // ==================== OBTENER TRANSACCIONES ====================

  /// Stream de todas las transacciones de un grupo
  Stream<List<TransactionModel>> getGroupTransactions(String groupId) {
    return _firestore
        .collection(FirebaseCollections.transactions)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .orderBy(FirebaseFields.fecha, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return TransactionModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<TransactionModel>()
              .toList();
        });
  }

  /// Stream de transacciones de un usuario específico en un grupo
  Stream<List<TransactionModel>> getUserTransactions(
    String groupId,
    String userId,
  ) {
    return _firestore
        .collection(FirebaseCollections.transactions)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .where(FirebaseFields.userId, isEqualTo: userId)
        .orderBy(FirebaseFields.fecha, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return TransactionModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<TransactionModel>()
              .toList();
        });
  }

  /// Obtiene transacciones de un usuario en un rango de fechas
  Future<ServiceResult<List<TransactionModel>>> getUserTransactionsInRange(
    String groupId,
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.userId, isEqualTo: userId)
          .where(FirebaseFields.fecha, isGreaterThanOrEqualTo: start)
          .where(FirebaseFields.fecha, isLessThanOrEqualTo: end)
          .orderBy(FirebaseFields.fecha, descending: true)
          .get();

      final transactions = snapshot.docs
          .map((doc) {
            try {
              return TransactionModel.fromMap(doc.data());
            } catch (e) {
              return null;
            }
          })
          .whereType<TransactionModel>()
          .toList();

      return ServiceResult.success(transactions);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener transacciones',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== ESTADÍSTICAS ====================

  /// Calcula estadísticas de transacciones de un usuario
  ///
  /// Retorna un mapa con:
  /// - ahorros: Total de ahorros
  /// - retiros: Total de retiros
  /// - pagos: Total de pagos de préstamos
  /// - intereses: Total de intereses pagados
  /// - total: Número total de transacciones
  Future<ServiceResult<Map<String, dynamic>>> getUserTransactionStats(
    String groupId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.userId, isEqualTo: userId)
          .get();

      double ahorros = 0.0;
      double retiros = 0.0;
      double pagos = 0.0;
      double intereses = 0.0;

      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromMap(doc.data());

        switch (transaction.tipo) {
          case TipoTransaccion.ahorro:
            ahorros += transaction.monto;
            break;
          case TipoTransaccion.retiro:
            retiros += transaction.monto;
            break;
          case TipoTransaccion.pagoPrestamo:
            pagos += transaction.monto;
            break;
          case TipoTransaccion.interes:
            intereses += transaction.monto;
            break;
          default:
            break;
        }
      }

      return ServiceResult.success({
        'ahorros': ahorros,
        'retiros': retiros,
        'pagos': pagos,
        'intereses': intereses,
        'saldoNeto': ahorros - retiros,
        'total': snapshot.docs.length,
      });
    } catch (e) {
      return ServiceResult.failure(
        'Error al calcular estadísticas',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Obtiene el resumen del mes actual para un usuario o grupo
  ///
  /// Si userId es null, calcula para todo el grupo
  Future<ServiceResult<Map<String, dynamic>>> getMonthSummary(
    String groupId, {
    String? userId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final inicioMes = DateTime.utc(now.year, now.month, 1);
      final finMes = DateTime.utc(now.year, now.month + 1, 0, 23, 59, 59);

      Query query = _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.fecha, isGreaterThanOrEqualTo: inicioMes)
          .where(FirebaseFields.fecha, isLessThanOrEqualTo: finMes);

      if (userId != null) {
        query = query.where(FirebaseFields.userId, isEqualTo: userId);
      }

      final snapshot = await query.get();

      double ahorros = 0.0;
      double retiros = 0.0;
      double pagos = 0.0;

      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        switch (transaction.tipo) {
          case TipoTransaccion.ahorro:
            ahorros += transaction.monto;
            break;
          case TipoTransaccion.retiro:
            retiros += transaction.monto;
            break;
          case TipoTransaccion.pagoPrestamo:
            pagos += transaction.monto;
            break;
          default:
            break;
        }
      }

      return ServiceResult.success({
        'ahorros': ahorros,
        'retiros': retiros,
        'pagos': pagos,
        'transacciones': snapshot.docs.length,
        'saldo': ahorros - retiros,
      });
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener resumen del mes',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== VALIDACIONES ====================

  /// Valida si un usuario tiene saldo suficiente para un retiro
  Future<ServiceResult<bool>> validateWithdrawal(
    String groupId,
    String userId,
    double amount,
  ) async {
    try {
      final statsResult = await getUserTransactionStats(groupId, userId);

      if (statsResult.isFailure) {
        return ServiceResult.failure(statsResult.errorMessage!);
      }

      final saldoNeto = statsResult.data!['saldoNeto'] as double;

      if (amount > saldoNeto) {
        return ServiceResult.failure(
          'Saldo insuficiente. Disponible: \$${saldoNeto.toStringAsFixed(2)}',
        );
      }

      return ServiceResult.success(true);
    } catch (e) {
      return ServiceResult.failure(
        'Error al validar retiro',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
