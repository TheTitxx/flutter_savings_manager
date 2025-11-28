import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_report_model.dart';
import '../models/transaction_model.dart';
import '../models/loan_request_model.dart';
import '../models/user_model.dart';
import 'core/service_result.dart';
import 'core/firebase_collections.dart';

/// Servicio especializado en generación de reportes financieros
///
/// Responsabilidades:
/// - Generar reportes de usuarios individuales
/// - Generar reportes consolidados de grupos
/// - Calcular estadísticas por período
/// - Análisis de movimientos (gráficas)
class ReportService {
  final FirebaseFirestore _firestore;

  ReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== REPORTES DE USUARIO ====================

  /// Genera un reporte financiero completo de un usuario
  ///
  /// Incluye:
  /// - Total de ahorros, retiros, préstamos
  /// - Saldo neto
  /// - Número de transacciones
  /// - Desglose por mes
  Future<ServiceResult<FinancialReport>> generateUserReport(
    String groupId,
    String userId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      // 1. Obtener usuario
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return ServiceResult.failure('Usuario no encontrado');
      }

      final user = UserModel.fromMap(userDoc.data()!);

      // 2. Obtener TODAS las transacciones del usuario
      final transactionsQuery = await _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.userId, isEqualTo: userId)
          .get();

      double totalAhorros = 0.0;
      double totalRetiros = 0.0;
      double totalPagado = 0.0;
      Map<String, double> ahorrosPorMes = {};
      Map<String, double> retirosPorMes = {};
      Map<String, double> pagosPorMes = {};
      int transaccionesContadas = 0;

      // 3. Procesar transacciones
      for (final doc in transactionsQuery.docs) {
        final transaction = TransactionModel.fromMap(doc.data());

        if (transaction.fecha.isBefore(fechaInicio) ||
            transaction.fecha.isAfter(fechaFin)) {
          continue;
        }

        transaccionesContadas++;

        final mesKey =
            '${transaction.fecha.year}-${transaction.fecha.month.toString().padLeft(2, '0')}';

        if (transaction.tipo == TipoTransaccion.ahorro) {
          totalAhorros += transaction.monto;
          ahorrosPorMes[mesKey] =
              (ahorrosPorMes[mesKey] ?? 0) + transaction.monto;
        } else if (transaction.tipo == TipoTransaccion.retiro) {
          totalRetiros += transaction.monto;
          retirosPorMes[mesKey] =
              (retirosPorMes[mesKey] ?? 0) + transaction.monto;
        } else if (transaction.tipo == TipoTransaccion.pagoPrestamo) {
          totalPagado += transaction.monto;
          pagosPorMes[mesKey] = (pagosPorMes[mesKey] ?? 0) + transaction.monto;
        } else if (transaction.tipo == TipoTransaccion.interes) {
          totalPagado += transaction.monto;
          pagosPorMes[mesKey] = (pagosPorMes[mesKey] ?? 0) + transaction.monto;
        }
      }

      // 4. Obtener préstamos (aprobados + completados)
      final loansQuery = await _firestore
          .collection(FirebaseCollections.loanRequests)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.solicitanteId, isEqualTo: userId)
          .get();

      double totalPrestamos = 0.0;
      int numeroPrestamos = 0;

      for (final doc in loansQuery.docs) {
        final loan = LoanRequestModel.fromMap(doc.data());

        if (loan.fechaSolicitud.isBefore(fechaInicio) ||
            loan.fechaSolicitud.isAfter(fechaFin)) {
          continue;
        }

        if (loan.estado == EstadoSolicitud.aprobada ||
            loan.estado == EstadoSolicitud.completada) {
          totalPrestamos += loan.montoSolicitado;
          numeroPrestamos++;
        }
      }

      // 5. Retornar reporte completo
      return ServiceResult.success(
        FinancialReport(
          userId: userId,
          userName: user.nombre,
          totalAhorros: totalAhorros,
          totalRetiros: totalRetiros,
          totalPrestamos: totalPrestamos,
          totalPagado: totalPagado,
          saldoNeto: totalAhorros - totalRetiros,
          numeroTransacciones: transaccionesContadas,
          numeroPrestamos: numeroPrestamos,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          ahorrosPorMes: ahorrosPorMes,
          retirosPorMes: retirosPorMes,
          pagosPorMes: pagosPorMes,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Error al generar reporte de usuario',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== REPORTES DE GRUPO ====================

  /// Genera un reporte consolidado del grupo completo
  ///
  /// Incluye:
  /// - Totales del grupo (ahorros, préstamos, intereses)
  /// - Reportes individuales de cada miembro
  /// - Top 3 ahorradores
  /// - Promedios por miembro
  Future<ServiceResult<GroupFinancialReport>> generateGroupReport(
    String groupId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      // 1. Obtener grupo
      final groupDoc = await _firestore
          .collection(FirebaseCollections.groups)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return ServiceResult.failure('Grupo no encontrado');
      }

      final groupData = groupDoc.data()!;
      final groupName = groupData['nombre'] ?? '';
      final miembrosIds = List<String>.from(groupData['miembrosIds'] ?? []);

      // 2. Generar reportes de cada miembro
      List<FinancialReport> reportesMiembros = [];

      for (final userId in miembrosIds) {
        final reporteResult = await generateUserReport(
          groupId,
          userId,
          fechaInicio,
          fechaFin,
        );

        if (reporteResult.isSuccess) {
          reportesMiembros.add(reporteResult.data!);
        }
      }

      // 3. Obtener transacciones del grupo para movimientos por mes
      final transactionsQuery = await _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .get();

      Map<String, double> movimientosPorMes = {};
      int transaccionesContadas = 0;

      for (final doc in transactionsQuery.docs) {
        final transaction = TransactionModel.fromMap(doc.data());

        if (transaction.fecha.isBefore(fechaInicio) ||
            transaction.fecha.isAfter(fechaFin)) {
          continue;
        }

        transaccionesContadas++;

        final mesKey =
            '${transaction.fecha.year}-${transaction.fecha.month.toString().padLeft(2, '0')}';

        if (transaction.esIngreso()) {
          movimientosPorMes[mesKey] =
              (movimientosPorMes[mesKey] ?? 0) + transaction.monto;
        } else {
          movimientosPorMes[mesKey] =
              (movimientosPorMes[mesKey] ?? 0) - transaction.monto;
        }
      }

      // 4. Calcular totales del grupo
      final totalAhorros = reportesMiembros
          .map((r) => r.totalAhorros)
          .fold(0.0, (a, b) => a + b);

      final totalRetiros = reportesMiembros
          .map((r) => r.totalRetiros)
          .fold(0.0, (a, b) => a + b);

      // 5. Calcular préstamos activos y totales pagados
      final loansActivosQuery = await _firestore
          .collection(FirebaseCollections.loanRequests)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .get();

      double prestamosActivos = 0.0;
      double totalPagadoPrestamos = 0.0;

      for (final doc in loansActivosQuery.docs) {
        final loan = LoanRequestModel.fromMap(doc.data());

        if (loan.fechaSolicitud.isBefore(fechaInicio) ||
            loan.fechaSolicitud.isAfter(fechaFin)) {
          continue;
        }

        if (loan.estado == EstadoSolicitud.aprobada ||
            loan.estado == EstadoSolicitud.completada) {
          if (loan.estado == EstadoSolicitud.aprobada && !loan.estaPagado) {
            // Calcular capital pendiente sin interés
            final capitalPendiente =
                loan.montoSolicitado -
                (loan.montoPagado *
                    (loan.montoSolicitado / loan.montoTotalConInteres));

            prestamosActivos += capitalPendiente;
          }

          totalPagadoPrestamos += loan.montoPagado;
        }
      }

      // 6. Calcular intereses devengados
      final interesesResult = await getInteresesDevengados(
        groupId,
        null,
        fechaInicio,
        fechaFin,
      );

      final totalInteresesPagados = interesesResult.isSuccess
          ? interesesResult.data!.values.fold(0.0, (a, b) => a + b)
          : 0.0;

      // 7. Obtener total en caja del grupo
      final totalEnCaja = groupData['totalAhorros'] ?? 0.0;

      // 8. Retornar reporte consolidado
      return ServiceResult.success(
        GroupFinancialReport(
          groupId: groupId,
          groupName: groupName,
          totalAhorros: totalAhorros,
          totalRetiros: totalRetiros,
          totalPrestamos: totalPagadoPrestamos,
          prestamosActivos: prestamosActivos,
          totalInteresesPagados: totalInteresesPagados,
          totalEnCaja: totalEnCaja,
          totalMiembros: miembrosIds.length,
          totalTransacciones: transaccionesContadas,
          reportesMiembros: reportesMiembros,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          movimientosPorMes: movimientosPorMes,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Error al generar reporte del grupo',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== ANÁLISIS POR PERÍODO ====================

  /// Obtiene movimientos por período para gráficas
  ///
  /// Períodos soportados:
  /// - 'semanal': Últimos 7 días
  /// - 'mensual_semanas': Semanas del mes actual
  /// - 'anual': 12 meses del año actual
  /// - 'multianual': Años completos
  Future<ServiceResult<Map<String, double>>> getMovimientosPorPeriodoYTipo(
    String groupId,
    String periodo,
    String? userId,
    String tipoGrafica,
  ) async {
    try {
      Map<String, double> resultado = {};

      // Obtener todas las transacciones
      Query baseQuery = _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId);

      if (userId != null) {
        baseQuery = baseQuery.where(FirebaseFields.userId, isEqualTo: userId);
      }

      final allTransactions = await baseQuery.get();

      if (allTransactions.docs.isEmpty) {
        return ServiceResult.success({});
      }

      // Encontrar la transacción más reciente
      List<TransactionModel> transactions = allTransactions.docs
          .map(
            (doc) =>
                TransactionModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();

      transactions.sort((a, b) => b.fecha.compareTo(a.fecha));
      final ahora = transactions.first.fecha;

      // Determinar rango según período
      DateTime inicio;
      final fin = ahora;

      switch (periodo) {
        case 'semanal':
          inicio = ahora.subtract(const Duration(days: 6));
          break;
        case 'mensual_semanas':
          inicio = DateTime(ahora.year, ahora.month, 1);
          break;
        case 'anual':
          inicio = DateTime(ahora.year, 1, 1);
          break;
        case 'multianual':
          transactions.sort((a, b) => a.fecha.compareTo(b.fecha));
          inicio = DateTime(transactions.first.fecha.year, 1, 1);
          break;
        default:
          inicio = ahora.subtract(const Duration(days: 6));
      }

      // Filtrar transacciones por rango de fechas
      final filteredTransactions = transactions
          .where(
            (t) =>
                t.fecha.isAfter(inicio.subtract(const Duration(days: 1))) &&
                t.fecha.isBefore(fin.add(const Duration(days: 1))),
          )
          .toList();

      // Procesar transacciones según tipo de gráfica
      for (final transaction in filteredTransactions) {
        String clave;

        switch (periodo) {
          case 'semanal':
            clave = _getDiaNombre(transaction.fecha.weekday);
            break;
          case 'mensual_semanas':
            final semana = ((transaction.fecha.day - 1) ~/ 7) + 1;
            clave = 'S$semana';
            break;
          case 'anual':
            clave = _getMesNombre(transaction.fecha.month);
            break;
          case 'multianual':
            clave = transaction.fecha.year.toString();
            break;
          default:
            clave = 'Desconocido';
        }

        // Determinar si incluir esta transacción según el tipo de gráfica
        bool incluirTransaccion = false;
        double monto = transaction.monto;
        bool esPositivo = true;

        switch (tipoGrafica) {
          // Personal
          case 'mis_ahorros':
            incluirTransaccion = transaction.tipo == TipoTransaccion.ahorro;
            break;
          case 'mis_retiros':
            incluirTransaccion = transaction.tipo == TipoTransaccion.retiro;
            break;
          case 'saldo_neto':
            incluirTransaccion =
                transaction.tipo == TipoTransaccion.ahorro ||
                transaction.tipo == TipoTransaccion.retiro;
            esPositivo = transaction.tipo == TipoTransaccion.ahorro;
            break;
          case 'mis_prestamos':
            incluirTransaccion = transaction.tipo == TipoTransaccion.prestamo;
            break;
          case 'mis_pagos':
            incluirTransaccion =
                transaction.tipo == TipoTransaccion.pagoPrestamo;
            break;

          // Grupo
          case 'ahorros_brutos':
            incluirTransaccion = transaction.tipo == TipoTransaccion.ahorro;
            break;
          case 'retiros':
            incluirTransaccion = transaction.tipo == TipoTransaccion.retiro;
            break;
          case 'prestamos_otorgados':
          case 'prestamos_activos':
            incluirTransaccion = transaction.tipo == TipoTransaccion.prestamo;
            break;
          case 'pagos_prestamos':
            incluirTransaccion =
                transaction.tipo == TipoTransaccion.pagoPrestamo;
            break;
          case 'intereses':
            incluirTransaccion = transaction.tipo == TipoTransaccion.interes;
            break;

          default:
            incluirTransaccion = true;
            esPositivo = transaction.esIngreso();
        }

        if (incluirTransaccion) {
          if (tipoGrafica == 'saldo_neto') {
            resultado[clave] =
                (resultado[clave] ?? 0) + (esPositivo ? monto : -monto);
          } else {
            resultado[clave] = (resultado[clave] ?? 0) + monto;
          }
        }
      }

      // Inicializar claves vacías según período
      if (periodo == 'semanal') {
        for (int i = 6; i >= 0; i--) {
          final dia = ahora.subtract(Duration(days: i));
          final nombreDia = _getDiaNombre(dia.weekday);
          resultado.putIfAbsent(nombreDia, () => 0);
        }
      } else if (periodo == 'mensual_semanas') {
        final diasEnMes = DateTime(ahora.year, ahora.month + 1, 0).day;
        final semanas = ((diasEnMes - 1) ~/ 7) + 1;
        for (int i = 1; i <= semanas; i++) {
          resultado.putIfAbsent('S$i', () => 0);
        }
      } else if (periodo == 'anual') {
        for (int i = 1; i <= 12; i++) {
          final mes = _getMesNombre(i);
          resultado.putIfAbsent(mes, () => 0);
        }
      }

      return ServiceResult.success(resultado);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener movimientos',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// Calcula intereses devengados en un período
  Future<ServiceResult<Map<String, double>>> getInteresesDevengados(
    String groupId,
    String? userId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      Query baseQuery = _firestore
          .collection(FirebaseCollections.transactions)
          .where(FirebaseFields.grupoId, isEqualTo: groupId)
          .where(FirebaseFields.tipo, isEqualTo: 'interes');

      if (userId != null) {
        baseQuery = baseQuery.where(FirebaseFields.userId, isEqualTo: userId);
      }

      final snapshot = await baseQuery.get();

      Map<String, double> interesesPorMes = {};

      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        if (transaction.fecha.isBefore(fechaInicio) ||
            transaction.fecha.isAfter(fechaFin)) {
          continue;
        }

        final mesKey =
            '${transaction.fecha.year}-${transaction.fecha.month.toString().padLeft(2, '0')}';

        interesesPorMes[mesKey] =
            (interesesPorMes[mesKey] ?? 0) + transaction.monto;
      }

      return ServiceResult.success(interesesPorMes);
    } catch (e) {
      return ServiceResult.failure(
        'Error al obtener intereses',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  // ==================== HELPERS PRIVADOS ====================

  /// Obtiene nombre del día de la semana
  String _getDiaNombre(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mie';
      case 4:
        return 'Jue';
      case 5:
        return 'Vie';
      case 6:
        return 'Sab';
      case 7:
        return 'Dom';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene nombre del mes
  String _getMesNombre(int month) {
    switch (month) {
      case 1:
        return 'Ene';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Abr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Ago';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dic';
      default:
        return 'Desconocido';
    }
  }
}
