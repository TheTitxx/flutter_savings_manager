import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/loan_request_model.dart';
import '../models/loan_payment_model.dart';
import '../models/transaction_model.dart';
import 'core/service_result.dart';
import 'core/firebase_collections.dart';

/// Servicio especializado en préstamos y pagos
///
/// Responsabilidades:
/// - Crear solicitudes de préstamo
/// - Sistema de votación
/// - Registrar pagos con cálculo de intereses
/// - Gestionar préstamos activos
class LoanService {
  final FirebaseFirestore _firestore;

  LoanService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== CREAR SOLICITUDES ====================

  /// Crea una nueva solicitud de préstamo
  ///
  /// El préstamo inicia en estado 'pendiente' y requiere votación
  Future<ServiceResult<LoanRequestModel>> createLoanRequest(
    LoanRequestModel loanRequest,
  ) async {
    try {
      await _firestore
          .collection(FirebaseCollections.loanRequests)
          .doc(loanRequest.id)
          .set(loanRequest.toMap());

      return ServiceResult.success(loanRequest);
    } catch (e) {
      return ServiceResult.failure(
        'Error al crear solicitud de préstamo',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== VOTACIONES ====================

  /// Registra un voto en una solicitud de préstamo
  ///
  /// Verifica automáticamente si debe cerrar la votación:
  /// - Todos votaron (excepto solicitante)
  /// - Pasaron 3 días
  Future<ServiceResult<void>> voteOnLoan({
    required String loanRequestId,
    required String userId,
    required String nombreUsuario,
    required bool aprobo,
    required int totalMiembros,
  }) async {
    try {
      // ✅ TRANSACCIÓN ATÓMICA para prevenir race conditions
      return await _firestore.runTransaction((transaction) async {
        final docRef = _firestore
            .collection(FirebaseCollections.loanRequests)
            .doc(loanRequestId);

        // 1. Leer documento DENTRO de la transacción
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception(ErrorMessages.loanNotFound);
        }

        final solicitud = LoanRequestModel.fromMap(doc.data()!);

        // 2. Validar estado
        if (solicitud.estado != EstadoSolicitud.pendiente) {
          throw Exception('La votación ya está cerrada');
        }

        // 3. Validar que no haya votado ya
        if (solicitud.usuarioYaVoto(userId)) {
          throw Exception('Ya has votado en esta solicitud');
        }

        // 4. Crear voto
        final nuevoVoto = Voto(
          userId: userId,
          nombreUsuario: nombreUsuario,
          aprobo: aprobo,
          fechaVoto: DateTime.now().toUtc(),
        );

        // 5. Agregar voto
        transaction.update(docRef, {
          FirebaseFields.votos: FieldValue.arrayUnion([nuevoVoto.toMap()]),
        });

        // 6. Verificar cierre automático
        final votosActualizados = [...solicitud.votos, nuevoVoto];
        final solicitudConNuevoVoto = solicitud.copyWith(
          votos: votosActualizados,
        );
        final nuevoEstado = solicitudConNuevoVoto.verificarCierrAutomatico(
          totalMiembros,
        );

        if (nuevoEstado != null) {
          debugPrint('🔒 Cerrando votación automáticamente: $nuevoEstado');

          transaction.update(docRef, {
            FirebaseFields.estado: nuevoEstado,
            'fechaAprobacion': DateTime.now().toUtc().toIso8601String(),
          });
        }

        return ServiceResult.successVoid();
      });
    } catch (e) {
      debugPrint('❌ Error en votación: $e');
      return ServiceResult.failure(
        e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : ErrorMessages.loanVoteFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Verifica si debe cerrar la votación automáticamente
  // Future<void> _checkAndCloseVoting(
  //   String loanRequestId,
  //   int totalMiembros,
  // ) async {
  //   // ✅ IMPORTANTE: Esta función ahora es solo para casos especiales
  //   // La mayoría del cierre automático se hace en voteOnLoan

  //   final doc = await _firestore
  //       .collection(FirebaseCollections.loanRequests)
  //       .doc(loanRequestId)
  //       .get();

  //   if (!doc.exists) return;

  //   final solicitud = LoanRequestModel.fromMap(doc.data()!);

  //   // Solo procesar si está pendiente
  //   if (solicitud.estado != EstadoSolicitud.pendiente) return;

  //   final nuevoEstado = solicitud.verificarCierrAutomatico(totalMiembros);

  //   if (nuevoEstado != null) {
  //     debugPrint('🕐 Cerrando votación por tiempo: $nuevoEstado');
  //     await _closeLoanVoting(
  //       loanRequestId: loanRequestId,
  //       aprobar: nuevoEstado == 'aprobada',
  //       montoSolicitado: solicitud.montoSolicitado,
  //       solicitanteId: solicitud.solicitanteId,
  //       grupoId: solicitud.grupoId,
  //       motivo: solicitud.motivo,
  //     );
  //   }
  // }

  /// Cierra una votación manualmente (solo presidente)
  Future<ServiceResult<void>> cerrarVotacionManual(
    String loanRequestId,
    bool aprobar,
  ) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.loanRequests)
          .doc(loanRequestId)
          .get();

      if (!doc.exists) {
        return ServiceResult.failure(ErrorMessages.loanNotFound);
      }

      final solicitud = LoanRequestModel.fromMap(doc.data()!);

      await _closeLoanVoting(
        loanRequestId: loanRequestId,
        aprobar: aprobar,
        montoSolicitado: solicitud.montoSolicitado,
        solicitanteId: solicitud.solicitanteId,
        grupoId: solicitud.grupoId,
        motivo: solicitud.motivo,
      );

      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Error al cerrar votación',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Ejecuta el cierre de votación (aprobada o rechazada)
  Future<void> _closeLoanVoting({
    required String loanRequestId,
    required bool aprobar,
    required double montoSolicitado,
    required String solicitanteId,
    required String grupoId,
    required String motivo,
  }) async {
    // 1. Actualizar estado
    await _firestore
        .collection(FirebaseCollections.loanRequests)
        .doc(loanRequestId)
        .update({
          FirebaseFields.estado: aprobar ? 'aprobada' : 'rechazada',
          'fechaAprobacion': DateTime.now().toUtc().toIso8601String(),
        });

    // 2. Si se aprobó, crear transacción y actualizar grupo
    if (aprobar) {
      // ✅ AQUÍ SE LLAMA LA FUNCIÓN QUE ACABAS DE ACTUALIZAR
      await _procesarPrestamoAprobado(
        loanRequestId: loanRequestId,
        montoSolicitado: montoSolicitado,
        solicitanteId: solicitanteId,
        grupoId: grupoId,
        motivo: motivo,
      );
    }
  }

  /// Procesa un préstamo aprobado
  Future<void> _procesarPrestamoAprobado({
    required String loanRequestId,
    required double montoSolicitado,
    required String solicitanteId,
    required String grupoId,
    required String motivo,
  }) async {
    try {
      // ✅ USAR TRANSACCIÓN ATÓMICA
      await _firestore.runTransaction((transaction) async {
        // 1. Crear transacción de préstamo
        final transactionRef = _firestore
            .collection(FirebaseCollections.transactions)
            .doc(DateTime.now().millisecondsSinceEpoch.toString());

        final transactionModel = TransactionModel(
          id: transactionRef.id,
          grupoId: grupoId,
          userId: solicitanteId,
          tipo: TipoTransaccion.prestamo,
          monto: montoSolicitado,
          fecha: DateTime.now().toUtc(),
          descripcion: 'Préstamo aprobado: $motivo',
          referencia: loanRequestId,
        );

        transaction.set(transactionRef, transactionModel.toMap());

        // 2. Actualizar totales del grupo
        final groupRef = _firestore
            .collection(FirebaseCollections.groups)
            .doc(grupoId);

        // ✅ ESTO ES LO IMPORTANTE: Restar del total de ahorros
        transaction.update(groupRef, {
          FirebaseFields.totalAhorros: FieldValue.increment(
            -montoSolicitado,
          ), // ✅ RESTA
          FirebaseFields.totalPrestamos: FieldValue.increment(
            montoSolicitado,
          ), // ✅ SUMA
        });

        debugPrint('💰 Préstamo procesado:');
        debugPrint('   Monto: \$$montoSolicitado');
        debugPrint('   Se restó de totalAhorros');
        debugPrint('   Se sumó a totalPrestamos');
      });
    } catch (e) {
      debugPrint('❌ Error al procesar préstamo aprobado: $e');
      // No lanzar error para no afectar la votación
    }
  }

  // ==================== PAGOS ====================

  /// Registra un pago de préstamo con cálculo proporcional de interés
  ///
  /// Proceso:
  /// 1. Valida que el préstamo esté activo
  /// 2. Calcula interés proporcional al monto pagado
  /// 3. Crea registro de pago
  /// 4. Actualiza préstamo
  /// 5. Crea transacciones (capital + interés)
  /// 6. Actualiza totales del grupo
  Future<ServiceResult<void>> registerLoanPayment({
    required String loanRequestId,
    required String userId,
    required double montoPago,
    required String descripcion,
  }) async {
    try {
      // ✅ TRANSACCIÓN ATÓMICA
      return await _firestore.runTransaction((transaction) async {
        // Referencias
        final loanRef = _firestore
            .collection(FirebaseCollections.loanRequests)
            .doc(loanRequestId);

        // 1. Leer préstamo DENTRO de la transacción
        final loanDoc = await transaction.get(loanRef);
        if (!loanDoc.exists) {
          throw Exception(ErrorMessages.loanNotFound);
        }

        final loan = LoanRequestModel.fromMap(loanDoc.data()!);

        // 2. Validaciones
        if (loan.estado != EstadoSolicitud.aprobada) {
          throw Exception(ErrorMessages.loanNotActive);
        }
        if (loan.solicitanteId != userId) {
          throw Exception(ErrorMessages.loanUnauthorized);
        }
        if (montoPago > loan.saldoPendiente + 0.01) {
          throw Exception('El pago excede el saldo pendiente');
        }

        // 3. Calcular interés proporcional (con redondeo)
        final montoTotal = loan.montoTotalConInteres;
        final montoCapital = loan.montoSolicitado;
        final interesTotal = montoTotal - montoCapital;
        final porcentajePago = montoPago / montoTotal;

        // ✅ Redondeo a 2 decimales
        final interesPorEstePago =
            (interesTotal * porcentajePago * 100).round() / 100;
        final capitalPorEstePago = montoPago - interesPorEstePago;
        final numeroCuota = (loan.montoPagado / loan.montoPorCuota).floor() + 1;

        debugPrint('💰 Procesando pago:');
        debugPrint('   Pago total: \$$montoPago');
        debugPrint('   Interés: \$$interesPorEstePago');
        debugPrint('   Capital: \$$capitalPorEstePago');

        // 4. Crear registro de pago
        final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
        final payment = LoanPaymentModel(
          id: paymentId,
          loanRequestId: loanRequestId,
          grupoId: loan.grupoId,
          userId: userId,
          montoPagado: montoPago,
          fechaPago: DateTime.now().toUtc(),
          descripcion: descripcion,
          numeroCuota: numeroCuota,
        );

        final paymentData = payment.toMap();
        paymentData['interesPagado'] = interesPorEstePago;
        paymentData['capitalPagado'] = capitalPorEstePago;
        paymentData['timestamp'] = FieldValue.serverTimestamp();

        transaction.set(
          _firestore
              .collection(FirebaseCollections.loanPayments)
              .doc(paymentId),
          paymentData,
        );

        // 5. Actualizar préstamo
        final nuevoMontoPagado = loan.montoPagado + montoPago;
        final prestamoCompletado = nuevoMontoPagado >= montoTotal - 0.01;

        transaction.update(loanRef, {
          FirebaseFields.montoPagado: prestamoCompletado
              ? montoTotal
              : nuevoMontoPagado,
          if (prestamoCompletado) FirebaseFields.estado: 'completada',
        });

        // 6. Crear transacción de capital
        final paymentTransaction = TransactionModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_pay_$numeroCuota',
          grupoId: loan.grupoId,
          userId: userId,
          tipo: TipoTransaccion.pagoPrestamo,
          monto: capitalPorEstePago,
          fecha: DateTime.now().toUtc(),
          descripcion: 'Pago capital cuota $numeroCuota/${loan.plazoCuotas}',
          referencia: loanRequestId,
        );

        transaction.set(
          _firestore
              .collection(FirebaseCollections.transactions)
              .doc(paymentTransaction.id),
          paymentTransaction.toMap(),
        );

        // 7. Crear transacción de interés
        if (interesPorEstePago > 0.01) {
          final interestTransaction = TransactionModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_int_$numeroCuota',
            grupoId: loan.grupoId,
            userId: loan.solicitanteId,
            tipo: TipoTransaccion.interes,
            monto: interesPorEstePago,
            fecha: DateTime.now().toUtc(),
            descripcion: 'Interés cuota $numeroCuota/${loan.plazoCuotas}',
            referencia: loanRequestId,
          );

          transaction.set(
            _firestore
                .collection(FirebaseCollections.transactions)
                .doc(interestTransaction.id),
            interestTransaction.toMap(),
          );
        }

        // 8. Actualizar grupo
        final groupRef = _firestore
            .collection(FirebaseCollections.groups)
            .doc(loan.grupoId);
        final totalAlFondo = capitalPorEstePago + interesPorEstePago;

        transaction.update(groupRef, {
          FirebaseFields.totalAhorros: FieldValue.increment(totalAlFondo),
        });

        if (prestamoCompletado) {
          transaction.update(groupRef, {
            FirebaseFields.totalPrestamos: FieldValue.increment(
              -loan.montoSolicitado,
            ),
          });
        }

        return ServiceResult.successVoid();
      });
    } catch (e) {
      return ServiceResult.failure(
        e.toString().contains('Exception:')
            ? e.toString().replaceAll('Exception: ', '')
            : ErrorMessages.loanPaymentFailed,
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== CONSULTAS ====================

  /// Stream de solicitudes pendientes de un grupo
  Stream<List<LoanRequestModel>> getPendingLoanRequests(String groupId) {
    return _firestore
        .collection(FirebaseCollections.loanRequests)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .where(FirebaseFields.estado, isEqualTo: 'pendiente')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return LoanRequestModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<LoanRequestModel>()
              .toList();
        });
  }

  /// Stream de todas las solicitudes de un grupo
  Stream<List<LoanRequestModel>> getGroupLoanRequests(String groupId) {
    return _firestore
        .collection(FirebaseCollections.loanRequests)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .orderBy('fechaSolicitud', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return LoanRequestModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<LoanRequestModel>()
              .toList();
        });
  }

  /// Stream de préstamos activos de un usuario
  Stream<List<LoanRequestModel>> getMyActiveLoans(
    String groupId,
    String userId,
  ) {
    return _firestore
        .collection(FirebaseCollections.loanRequests)
        .where(FirebaseFields.grupoId, isEqualTo: groupId)
        .where(FirebaseFields.solicitanteId, isEqualTo: userId)
        .where(FirebaseFields.estado, isEqualTo: 'aprobada')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return LoanRequestModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<LoanRequestModel>()
              .where((loan) => !loan.estaPagado)
              .toList();
        });
  }

  /// Stream de pagos de un préstamo
  Stream<List<LoanPaymentModel>> getLoanPayments(String loanRequestId) {
    return _firestore
        .collection(FirebaseCollections.loanPayments)
        .where(FirebaseFields.loanRequestId, isEqualTo: loanRequestId)
        .orderBy('fechaPago', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return LoanPaymentModel.fromMap(doc.data());
                } catch (e) {
                  return null;
                }
              })
              .whereType<LoanPaymentModel>()
              .toList();
        });
  }

  /// Calcula el total de préstamos activos (solo capital pendiente)
  Future<ServiceResult<double>> getPrestamosActivosTotal(String groupId) async {
    try {
      final loansQuery = await _firestore
          .collection(FirebaseCollections.loanRequests)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.estado, isEqualTo: 'aprobada')
          .get();

      double totalPendiente = 0.0;

      for (final doc in loansQuery.docs) {
        final loan = LoanRequestModel.fromMap(doc.data());

        if (!loan.estaPagado) {
          // Calcular solo capital pendiente (sin interés)
          final totalConInteres = loan.montoTotalConInteres;
          final capitalOriginal = loan.montoSolicitado;
          final porcentajePagado = loan.montoPagado / totalConInteres;
          final capitalPagado = capitalOriginal * porcentajePagado;
          final capitalPendiente = capitalOriginal - capitalPagado;

          totalPendiente += capitalPendiente;
        }
      }

      return ServiceResult.success(totalPendiente);
    } catch (e) {
      return ServiceResult.failure(
        'Error al calcular préstamos activos',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Resumen de préstamos activos de un usuario
  Future<ServiceResult<Map<String, dynamic>>> getUserActiveLoansSummary(
    String groupId,
    String userId,
  ) async {
    try {
      final loansQuery = await _firestore
          .collection(FirebaseCollections.loanRequests)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.solicitanteId, isEqualTo: userId)
          .where(FirebaseFields.estado, isEqualTo: 'aprobada')
          .get();

      double totalPendiente = 0.0;
      int numeroPrestamos = 0;

      for (final doc in loansQuery.docs) {
        final loan = LoanRequestModel.fromMap(doc.data());

        if (!loan.estaPagado) {
          totalPendiente += loan.saldoPendiente;
          numeroPrestamos++;
        }
      }

      return ServiceResult.success({
        'totalPendiente': totalPendiente,
        'numeroPrestamos': numeroPrestamos,
      });
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener resumen de préstamos',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
