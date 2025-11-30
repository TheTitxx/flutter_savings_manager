import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/report_service.dart';

// Models
import '../../models/financial_report_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';

/// ✅ REPORTS SCREEN - OPTIMIZADO
///
/// Cambios principales:
/// - ✅ Usa ReportService con Service Locator
/// - ✅ Mejor organización del código
/// - ✅ Widgets separados por responsabilidad
/// - ✅ Manejo de estados mejorado
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // 🎯 Service Locator
  final ReportService _reportService = getIt<ReportService>();

  // Estado
  bool _isLoading = false;
  String _selectedPeriod = '30';
  String _selectedChartPeriod = 'semanal';
  String _selectedChartTypePersonal = 'saldo_neto';
  String _selectedChartTypeGroup = 'ahorros_brutos';
  FinancialReport? _userReport;
  GroupFinancialReport? _groupReport;
  bool _showGroupReport = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.selectedGroup == null ||
        authProvider.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    DateTime fechaFin = DateTime.now();
    DateTime fechaInicio = fechaFin.subtract(
      Duration(days: int.parse(_selectedPeriod)),
    );

    // Cargar reporte personal
    final userResult = await _reportService.generateUserReport(
      authProvider.selectedGroup!.id,
      authProvider.currentUser!.uid,
      fechaInicio,
      fechaFin,
    );

    // Si es presidente, cargar también reporte del grupo
    GroupFinancialReport? groupReport;
    if (authProvider.isPresident) {
      final groupResult = await _reportService.generateGroupReport(
        authProvider.selectedGroup!.id,
        fechaInicio,
        fechaFin,
      );
      groupReport = groupResult.data;
    }

    setState(() {
      _userReport = userResult.data;
      _groupReport = groupReport;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Financieros'),
        actions: [_buildPeriodSelector()],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Cargando reportes...')
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle entre personal y grupo (solo presidente)
                    if (authProvider.isPresident && _groupReport != null) ...[
                      _buildReportToggle(),
                      const SizedBox(height: 24),
                    ],

                    // Mostrar reporte según selección
                    if (_showGroupReport && _groupReport != null)
                      _GroupReportContent(
                        report: _groupReport!,
                        currencyFormat: currencyFormat,
                        selectedChartPeriod: _selectedChartPeriod,
                        selectedChartType: _selectedChartTypeGroup,
                        reportService: _reportService,
                        onChartPeriodChanged: (period) =>
                            setState(() => _selectedChartPeriod = period),
                        onChartTypeChanged: (type) =>
                            setState(() => _selectedChartTypeGroup = type),
                      )
                    else if (_userReport != null)
                      _UserReportContent(
                        report: _userReport!,
                        currencyFormat: currencyFormat,
                        selectedChartPeriod: _selectedChartPeriod,
                        selectedChartType: _selectedChartTypePersonal,
                        reportService: _reportService,
                        groupId: authProvider.selectedGroup!.id,
                        userId: authProvider.currentUser!.uid,
                        onChartPeriodChanged: (period) =>
                            setState(() => _selectedChartPeriod = period),
                        onChartTypeChanged: (type) =>
                            setState(() => _selectedChartTypePersonal = type),
                      )
                    else
                      _buildNoDataWidget(),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.calendar_today),
      onSelected: (value) {
        setState(() => _selectedPeriod = value);
        _loadReports();
      },
      itemBuilder: (context) => [
        _buildPeriodMenuItem('7', 'Últimos 7 días'),
        _buildPeriodMenuItem('30', 'Últimos 30 días'),
        _buildPeriodMenuItem('90', 'Últimos 3 meses'),
        _buildPeriodMenuItem('365', 'Último año'),
      ],
    );
  }

  PopupMenuItem<String> _buildPeriodMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: _selectedPeriod == value
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReportToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showGroupReport = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showGroupReport ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Mi Reporte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_showGroupReport ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showGroupReport = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showGroupReport ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Reporte del Grupo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _showGroupReport ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return const EmptyStateWidget(
      icon: Icons.assessment,
      title: 'No hay datos para este periodo',
    );
  }
}

// ==================== USER REPORT CONTENT ====================

class _UserReportContent extends StatelessWidget {
  final FinancialReport report;
  final NumberFormat currencyFormat;
  final String selectedChartPeriod;
  final String selectedChartType;
  final ReportService reportService;
  final String groupId;
  final String userId;
  final Function(String) onChartPeriodChanged;
  final Function(String) onChartTypeChanged;

  const _UserReportContent({
    required this.report,
    required this.currencyFormat,
    required this.selectedChartPeriod,
    required this.selectedChartType,
    required this.reportService,
    required this.groupId,
    required this.userId,
    required this.onChartPeriodChanged,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen Personal',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Tarjetas de estadísticas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ahorros',
                currencyFormat.format(report.totalAhorros),
                Icons.savings,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Retiros',
                currencyFormat.format(report.totalRetiros),
                Icons.arrow_circle_down,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Préstamos',
                currencyFormat.format(report.totalPrestamos),
                Icons.credit_card,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pagos',
                currencyFormat.format(report.totalPagado),
                Icons.payment,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Saldo neto
        Card(
          color: report.saldoNeto >= 0
              ? Colors.green.shade50
              : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: report.saldoNeto >= 0 ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Saldo Neto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormat.format(report.saldoNeto),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: report.saldoNeto >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gráfica
        const Text(
          'Mis Movimientos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ChartTypeSelector(
          isGroup: false,
          selectedType: selectedChartType,
          onTypeChanged: onChartTypeChanged,
        ),
        const SizedBox(height: 16),
        _PeriodSelector(
          selectedPeriod: selectedChartPeriod,
          onPeriodChanged: onChartPeriodChanged,
        ),
        const SizedBox(height: 16),
        _ChartWidget(
          reportService: reportService,
          groupId: groupId,
          userId: userId,
          period: selectedChartPeriod,
          chartType: selectedChartType,
        ),
        const SizedBox(height: 24),

        // Estadísticas
        const Text(
          'Estadísticas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStatisticsCard(report, currencyFormat),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(
    FinancialReport report,
    NumberFormat currencyFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              'Total de transacciones',
              '${report.numeroTransacciones}',
              Icons.receipt_long,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Préstamos solicitados',
              '${report.numeroPrestamos}',
              Icons.request_quote,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Promedio mensual',
              currencyFormat.format(report.promedioMensualAhorros),
              Icons.trending_up,
            ),
            if (report.mesMayorAhorro() != null) ...[
              const Divider(height: 24),
              _buildStatRow(
                'Mejor mes',
                _formatMonthKey(report.mesMayorAhorro()!),
                Icons.star,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatMonthKey(String key) {
    List<String> parts = key.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    DateTime date = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(date);
  }
}

// ==================== GROUP REPORT CONTENT ====================

class _GroupReportContent extends StatelessWidget {
  final GroupFinancialReport report;
  final NumberFormat currencyFormat;
  final String selectedChartPeriod;
  final String selectedChartType;
  final ReportService reportService;
  final Function(String) onChartPeriodChanged;
  final Function(String) onChartTypeChanged;

  const _GroupReportContent({
    required this.report,
    required this.currencyFormat,
    required this.selectedChartPeriod,
    required this.selectedChartType,
    required this.reportService,
    required this.onChartPeriodChanged,
    required this.onChartTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del Grupo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Tarjetas de estadísticas (2x3)
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ahorros',
                currencyFormat.format(report.totalAhorros),
                Icons.savings,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Retiros',
                currencyFormat.format(report.totalRetiros),
                Icons.arrow_circle_down,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Préstamos Activos',
                currencyFormat.format(report.prestamosActivos),
                Icons.credit_card,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Pagado',
                currencyFormat.format(report.totalPrestamos),
                Icons.check_circle,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Intereses',
                currencyFormat.format(report.totalInteresesPagados),
                Icons.trending_up,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total en Caja',
                currencyFormat.format(report.totalEnCaja),
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Miembros',
                '${report.totalMiembros}',
                Icons.people,
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Transacciones',
                '${report.totalTransacciones}',
                Icons.receipt_long,
                Colors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Promedio por miembro
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      'Promedio por Miembro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormat.format(report.promedioTotalPorMiembro),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gráfica del grupo
        const Text(
          'Movimientos del Grupo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ChartTypeSelector(
          isGroup: true,
          selectedType: selectedChartType,
          onTypeChanged: onChartTypeChanged,
        ),
        const SizedBox(height: 16),
        _PeriodSelector(
          selectedPeriod: selectedChartPeriod,
          onPeriodChanged: onChartPeriodChanged,
        ),
        const SizedBox(height: 16),
        _ChartWidget(
          reportService: reportService,
          groupId: report.groupId,
          userId: null,
          period: selectedChartPeriod,
          chartType: selectedChartType,
        ),
        const SizedBox(height: 24),

        // Top Ahorradores
        const Text(
          'Top Ahorradores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...report.topAhorradores.asMap().entries.map((entry) {
          int index = entry.key;
          FinancialReport miembro = entry.value;
          return _buildTopAhorradorCard(
            index,
            miembro,
            report.totalAhorros,
            currencyFormat,
          );
        }),
        const SizedBox(height: 24),

        // Todos los miembros
        const Text(
          'Todos los Miembros',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...report.reportesMiembros.map((miembro) {
          return _buildMemberCard(miembro, currencyFormat);
        }),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAhorradorCard(
    int index,
    FinancialReport miembro,
    double totalGrupo,
    NumberFormat currencyFormat,
  ) {
    final colors = [Colors.amber, Colors.grey, Colors.brown];
    final color = index < 3 ? colors[index] : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          miembro.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${miembro.numeroTransacciones} transacciones',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(miembro.totalAhorros),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            Text(
              '${miembro.calcularPorcentajeParticipacion(totalGrupo).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    FinancialReport miembro,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            miembro.userName[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        title: Text(
          miembro.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Saldo: ${currencyFormat.format(miembro.saldoNeto)}',
          style: TextStyle(
            color: miembro.saldoNeto >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow(
                  'Ahorros',
                  currencyFormat.format(miembro.totalAhorros),
                  Icons.savings,
                ),
                const Divider(height: 16),
                _buildStatRow(
                  'Retiros',
                  currencyFormat.format(miembro.totalRetiros),
                  Icons.arrow_circle_down,
                ),
                const Divider(height: 16),
                _buildStatRow(
                  'Préstamos',
                  currencyFormat.format(miembro.totalPrestamos),
                  Icons.credit_card,
                ),
                const Divider(height: 16),
                _buildStatRow(
                  'Transacciones',
                  '${miembro.numeroTransacciones}',
                  Icons.receipt_long,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==================== CHART TYPE SELECTOR ====================

class _ChartTypeSelector extends StatelessWidget {
  final bool isGroup;
  final String selectedType;
  final Function(String) onTypeChanged;

  const _ChartTypeSelector({
    required this.isGroup,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 22, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Tipo de Gráfica',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade900,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: isGroup
                    ? _buildGroupDropdownItems()
                    : _buildPersonalDropdownItems(),
                onChanged: (value) {
                  if (value != null) onTypeChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildPersonalDropdownItems() {
    final options = [
      {'value': 'mis_ahorros', 'label': 'Mis Ahorros', 'icon': Icons.savings},
      {
        'value': 'mis_retiros',
        'label': 'Mis Retiros',
        'icon': Icons.arrow_circle_down,
      },
      {
        'value': 'saldo_neto',
        'label': 'Mi Saldo Neto',
        'icon': Icons.account_balance,
      },
      {
        'value': 'mis_prestamos',
        'label': 'Mis Préstamos',
        'icon': Icons.credit_card,
      },
      {
        'value': 'mis_pagos',
        'label': 'Pagos de Préstamos',
        'icon': Icons.payment,
      },
      {
        'value': 'intereses',
        'label': 'Mis Intereses Pagados',
        'icon': Icons.trending_up,
      },
    ];

    return options.map((option) {
      return DropdownMenuItem<String>(
        value: option['value'] as String,
        child: Row(
          children: [
            Icon(
              option['icon'] as IconData,
              size: 20,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 12),
            Text(
              option['label'] as String,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildGroupDropdownItems() {
    final options = [
      {
        'value': 'ahorros_brutos',
        'label': 'Ahorros Totales',
        'icon': Icons.savings,
      },
      {'value': 'retiros', 'label': 'Retiros', 'icon': Icons.arrow_circle_down},
      {
        'value': 'saldo_neto',
        'label': 'Saldo Neto',
        'icon': Icons.account_balance,
      },
      {
        'value': 'prestamos_otorgados',
        'label': 'Préstamos Otorgados',
        'icon': Icons.credit_card,
      },
      {
        'value': 'pagos_prestamos',
        'label': 'Pagos de Préstamos',
        'icon': Icons.payment,
      },
      {
        'value': 'intereses',
        'label': 'Intereses Generados',
        'icon': Icons.trending_up,
      },
    ];

    return options.map((option) {
      return DropdownMenuItem<String>(
        value: option['value'] as String,
        child: Row(
          children: [
            Icon(
              option['icon'] as IconData,
              size: 20,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 12),
            Text(
              option['label'] as String,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ==================== PERIOD SELECTOR ====================

class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPeriodOption('Semana', 'semanal'),
          _buildPeriodOption('Mes', 'mensual_semanas'),
          _buildPeriodOption('Año', 'anual'),
          _buildPeriodOption('Multi-año', 'multianual'),
        ],
      ),
    );
  }

  Widget _buildPeriodOption(String label, String value) {
    bool isSelected = selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CHART WIDGET ====================

class _ChartWidget extends StatelessWidget {
  final ReportService reportService;
  final String groupId;
  final String? userId;
  final String period;
  final String chartType;

  const _ChartWidget({
    required this.reportService,
    required this.groupId,
    required this.userId,
    required this.period,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: reportService
          .getMovimientosPorPeriodoYTipo(groupId, period, userId, chartType)
          .then((result) => result.data ?? {}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No hay datos para este periodo',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _getChartTitle(period),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: _buildBarChart(
                    snapshot.data!,
                    _getChartColor(chartType),
                    period,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarChart(
    Map<String, double> data,
    Color barColor,
    String periodo,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No hay datos disponibles para este periodo',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Ordenar claves correctamente según el periodo
    List<String> sortedKeys = _getSortedKeys(data, periodo);

    if (sortedKeys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No hay datos para este periodo',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calcular rango para el eje Y
    List<double> valores = sortedKeys.map((k) => data[k] ?? 0).toList();
    double maxY = valores.reduce((a, b) => a > b ? a : b);
    double minY = valores.reduce((a, b) => a < b ? a : b);

    // Ajustar rangos con margen
    if (minY < 0) {
      minY = minY * 1.2;
      maxY = maxY > 0 ? maxY * 1.2 : 100;
    } else {
      minY = 0;
      maxY = maxY > 0 ? maxY * 1.2 : 100;
    }

    // Asegurar que hay diferencia entre min y max
    if ((maxY - minY).abs() < 10) {
      maxY = maxY + 50;
      if (minY < 0) minY = minY - 50;
    }

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: minY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (group.x.toInt() >= sortedKeys.length) return null;

              String label = sortedKeys[group.x.toInt()];
              String valor = currencyFormat.format(rod.toY.abs());
              String signo = rod.toY >= 0 ? '+' : '-';

              return BarTooltipItem(
                '$label\n$signo$valor',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= sortedKeys.length) {
                  return const SizedBox.shrink();
                }

                String key = sortedKeys[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 5).abs(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        barGroups: sortedKeys.asMap().entries.map((entry) {
          double value = data[entry.value] ?? 0;

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: value,
                color: value >= 0 ? barColor : Colors.red,
                width: 16,
                borderRadius: BorderRadius.vertical(
                  top: value >= 0 ? const Radius.circular(4) : Radius.zero,
                  bottom: value < 0 ? const Radius.circular(4) : Radius.zero,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ==================== HELPERS ====================

  List<String> _getSortedKeys(Map<String, double> data, String periodo) {
    switch (periodo) {
      case 'semanal':
        final ordenDias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
        return ordenDias.where((dia) => data.containsKey(dia)).toList();

      case 'mensual_semanas':
        return data.keys.toList()..sort((a, b) {
          int numA = int.tryParse(a.replaceAll('S', '')) ?? 0;
          int numB = int.tryParse(b.replaceAll('S', '')) ?? 0;
          return numA.compareTo(numB);
        });

      case 'anual':
        final ordenMeses = [
          'Ene',
          'Feb',
          'Mar',
          'Abr',
          'May',
          'Jun',
          'Jul',
          'Ago',
          'Sep',
          'Oct',
          'Nov',
          'Dic',
        ];
        return ordenMeses.where((mes) => data.containsKey(mes)).toList();

      default:
        return data.keys.toList()..sort();
    }
  }

  Color _getChartColor(String chartType) {
    switch (chartType) {
      case 'mis_ahorros':
      case 'ahorros_brutos':
        return Colors.green;

      case 'mis_retiros':
      case 'retiros':
        return Colors.red;

      case 'saldo_neto':
        return Colors.blue;

      case 'mis_prestamos':
      case 'prestamos_otorgados':
      case 'prestamos_activos':
        return Colors.orange;

      case 'mis_pagos':
      case 'pagos_prestamos':
        return Colors.purple;

      case 'intereses':
        return Colors.teal;

      default:
        return Colors.blue;
    }
  }

  String _getChartTitle(String periodo) {
    switch (periodo) {
      case 'semanal':
        return 'Últimos 7 días';
      case 'mensual_semanas':
        return 'Semanas del mes actual';
      case 'anual':
        return 'Meses del año ${DateTime.now().year}';
      case 'multianual':
        return 'Movimientos por año';
      default:
        return 'Estadísticas';
    }
  }
}
