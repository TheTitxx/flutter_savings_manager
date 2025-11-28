/// ✅ FINANCIAL REPORT - Reporte individual optimizado
class FinancialReport {
  final String userId;
  final String userName;
  final double totalAhorros;
  final double totalRetiros;
  final double totalPrestamos;
  final double totalPagado;
  final double saldoNeto;
  final int numeroTransacciones;
  final int numeroPrestamos;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final Map<String, double> ahorrosPorMes;
  final Map<String, double> retirosPorMes;
  final Map<String, double> pagosPorMes;

  FinancialReport({
    required this.userId,
    required this.userName,
    required this.totalAhorros,
    required this.totalRetiros,
    required this.totalPrestamos,
    required this.totalPagado,
    required this.saldoNeto,
    required this.numeroTransacciones,
    required this.numeroPrestamos,
    required this.fechaInicio,
    required this.fechaFin,
    required this.ahorrosPorMes,
    required this.retirosPorMes,
    required this.pagosPorMes,
  });

  // ==================== GETTERS ÚTILES ====================

  /// Porcentaje de participación en el grupo
  double calcularPorcentajeParticipacion(double totalGrupo) {
    if (totalGrupo == 0) return 0.0;
    return (totalAhorros / totalGrupo) * 100;
  }

  /// Mes con mayor ahorro
  String? mesMayorAhorro() {
    if (ahorrosPorMes.isEmpty) return null;
    var maxEntry = ahorrosPorMes.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return maxEntry.key;
  }

  /// Monto del mes con mayor ahorro
  double get montoMesMayorAhorro {
    if (ahorrosPorMes.isEmpty) return 0.0;
    return ahorrosPorMes.values.reduce((a, b) => a > b ? a : b);
  }

  /// Promedio mensual de ahorros
  double get promedioMensualAhorros {
    if (ahorrosPorMes.isEmpty) return 0.0;
    double total = ahorrosPorMes.values.reduce((a, b) => a + b);
    return total / ahorrosPorMes.length;
  }

  /// Promedio mensual de retiros
  double get promedioMensualRetiros {
    if (retirosPorMes.isEmpty) return 0.0;
    double total = retirosPorMes.values.reduce((a, b) => a + b);
    return total / retirosPorMes.length;
  }

  /// Total de meses con actividad
  int get mesesConActividad {
    final meses = <String>{
      ...ahorrosPorMes.keys,
      ...retirosPorMes.keys,
      ...pagosPorMes.keys,
    };
    return meses.length;
  }

  /// Saldo es positivo
  bool get saldoPositivo => saldoNeto > 0;

  /// Tiene préstamos pendientes
  bool get tienePrestamosPendientes => totalPrestamos > totalPagado;

  /// Porcentaje de préstamo pagado
  double get porcentajePrestamoPagado {
    if (totalPrestamos == 0) return 0;
    return (totalPagado / totalPrestamos) * 100;
  }

  // ==================== ANÁLISIS ====================

  /// Tendencia de ahorro (comparar primero vs último mes)
  String get tendenciaAhorro {
    if (ahorrosPorMes.length < 2) return 'Sin datos';

    final meses = ahorrosPorMes.keys.toList()..sort();
    final primerMes = ahorrosPorMes[meses.first] ?? 0;
    final ultimoMes = ahorrosPorMes[meses.last] ?? 0;

    if (ultimoMes > primerMes) return 'Creciente';
    if (ultimoMes < primerMes) return 'Decreciente';
    return 'Estable';
  }

  /// Ratio ahorro/retiro
  double get ratioAhorroRetiro {
    if (totalRetiros == 0) return totalAhorros > 0 ? double.infinity : 0;
    return totalAhorros / totalRetiros;
  }

  @override
  String toString() {
    return 'FinancialReport($userName: ahorros=$totalAhorros, saldo=$saldoNeto)';
  }
}

// ==================== GROUP FINANCIAL REPORT ====================

/// ✅ GROUP FINANCIAL REPORT - Reporte consolidado optimizado
class GroupFinancialReport {
  final String groupId;
  final String groupName;
  final double totalAhorros;
  final double totalRetiros;
  final double totalPrestamos;
  final double prestamosActivos;
  final double totalInteresesPagados;
  final double totalEnCaja;
  final int totalMiembros;
  final int totalTransacciones;
  final List<FinancialReport> reportesMiembros;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final Map<String, double> movimientosPorMes;

  GroupFinancialReport({
    required this.groupId,
    required this.groupName,
    required this.totalAhorros,
    required this.totalRetiros,
    required this.totalPrestamos,
    required this.prestamosActivos,
    required this.totalInteresesPagados,
    required this.totalEnCaja,
    required this.totalMiembros,
    required this.totalTransacciones,
    required this.reportesMiembros,
    required this.fechaInicio,
    required this.fechaFin,
    required this.movimientosPorMes,
  });

  // ==================== GETTERS DE RANKING ====================

  /// Top 3 ahorradores
  List<FinancialReport> get topAhorradores {
    var sorted = List<FinancialReport>.from(reportesMiembros);
    sorted.sort((a, b) => b.totalAhorros.compareTo(a.totalAhorros));
    return sorted.take(3).toList();
  }

  /// Top 5 ahorradores
  List<FinancialReport> get top5Ahorradores {
    var sorted = List<FinancialReport>.from(reportesMiembros);
    sorted.sort((a, b) => b.totalAhorros.compareTo(a.totalAhorros));
    return sorted.take(5).toList();
  }

  /// Miembros más activos (por transacciones)
  List<FinancialReport> get miembrosMasActivos {
    var sorted = List<FinancialReport>.from(reportesMiembros);
    sorted.sort(
      (a, b) => b.numeroTransacciones.compareTo(a.numeroTransacciones),
    );
    return sorted.take(5).toList();
  }

  // ==================== PROMEDIOS ====================

  /// Promedio de ahorros por miembro
  double get promedioAhorrosPorMiembro {
    if (totalMiembros == 0) return 0.0;
    return totalAhorros / totalMiembros;
  }

  /// Promedio de transacciones por miembro
  double get promedioTransaccionesPorMiembro {
    if (totalMiembros == 0) return 0.0;
    return totalTransacciones / totalMiembros;
  }

  /// Promedio total por miembro (ahorros + intereses)
  double get promedioTotalPorMiembro {
    if (totalMiembros == 0) return 0.0;
    return totalEnCaja / totalMiembros;
  }

  // ==================== ANÁLISIS FINANCIERO ====================

  /// Tasa de morosidad (préstamos pendientes / préstamos totales)
  double calcularTasaMorosidad() {
    if (totalPrestamos == 0) return 0.0;

    double prestamosPendientes = reportesMiembros
        .map((r) => r.totalPrestamos - r.totalPagado)
        .reduce((a, b) => a + b);

    return (prestamosPendientes / totalPrestamos) * 100;
  }

  /// Capital circulante (ahorros - préstamos activos)
  double get capitalCirculante => totalAhorros - prestamosActivos;

  /// Liquidez del grupo (ratio ahorros/préstamos)
  double get ratioLiquidez {
    if (prestamosActivos == 0) return totalAhorros > 0 ? double.infinity : 0;
    return totalAhorros / prestamosActivos;
  }

  /// Retorno sobre ahorros (intereses / ahorros)
  double get retornoSobreAhorros {
    if (totalAhorros == 0) return 0;
    return (totalInteresesPagados / totalAhorros) * 100;
  }

  // ==================== VALIDACIONES ====================

  /// Grupo está sano (liquidez > 1 y morosidad < 20%)
  bool get grupoSaludable {
    return ratioLiquidez >= 1.0 && calcularTasaMorosidad() < 20;
  }

  /// Tiene actividad (al menos 1 transacción)
  bool get tieneActividad => totalTransacciones > 0;

  /// Todos los miembros participan
  bool get todosParticipan {
    return reportesMiembros.every((r) => r.numeroTransacciones > 0);
  }

  // ==================== ESTADÍSTICAS MENSUALES ====================

  /// Mes con mayor movimiento
  String? mesMayorMovimiento() {
    if (movimientosPorMes.isEmpty) return null;
    var maxEntry = movimientosPorMes.entries.reduce(
      (a, b) => a.value.abs() > b.value.abs() ? a : b,
    );
    return maxEntry.key;
  }

  /// Promedio mensual de movimientos
  double get promedioMensualMovimientos {
    if (movimientosPorMes.isEmpty) return 0.0;
    double total = movimientosPorMes.values
        .map((v) => v.abs())
        .reduce((a, b) => a + b);
    return total / movimientosPorMes.length;
  }

  @override
  String toString() {
    return 'GroupFinancialReport($groupName: miembros=$totalMiembros, ahorros=$totalAhorros)';
  }
}
