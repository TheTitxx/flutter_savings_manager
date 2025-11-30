import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/transaction_service.dart';

// Models
import '../../models/transaction_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/custom_cards.dart';

/// ✅ ALL TRANSACTIONS SCREEN - OPTIMIZADO
///
/// Cambios principales:
/// - Usa TransactionService con Service Locator
/// - Usa widgets reutilizables
/// - Mejor organización del código
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  // 🎯 Service Locator
  final TransactionService _transactionService = getIt<TransactionService>();

  // Filtros
  String _filterType = 'todas';
  String _sortBy = 'reciente';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final group = authProvider.selectedGroup;
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transacciones')),
        body: const EmptyStateWidget(
          icon: Icons.group_off,
          title: 'No hay grupo seleccionado',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas las Transacciones'),
        actions: [_buildFilterButton(), _buildSortButton()],
      ),
      body: Column(
        children: [
          // Chip de filtro activo
          if (_filterType != 'todas') _buildActiveFilterChip(),

          // Lista de transacciones
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getGroupTransactions(group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(
                    message: 'Cargando transacciones...',
                  );
                }

                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    message: 'Error al cargar transacciones',
                    onRetry: () => setState(() {}),
                  );
                }

                var transactions = snapshot.data ?? [];

                // Aplicar filtros
                transactions = _applyFilters(transactions);

                if (transactions.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.receipt_long,
                    title: _filterType == 'todas'
                        ? 'No hay transacciones aún'
                        : 'No hay transacciones de este tipo',
                  );
                }

                // Calcular totales
                final totals = _calculateTotals(transactions);

                return Column(
                  children: [
                    // Resumen de totales
                    _buildSummaryCard(totals, currencyFormat),

                    // Lista
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return TransactionCard(
                            tipo: transaction.tipoNombre,
                            monto: transaction.monto,
                            fecha: transaction.fecha,
                            descripcion: transaction.descripcion,
                            icon: transaction.icono,
                            color: transaction.color,
                            isIncome: transaction.esIngreso(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FILTROS ====================

  Widget _buildFilterButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) => setState(() => _filterType = value),
      itemBuilder: (context) => [
        _buildFilterMenuItem(
          'todas',
          'Todas',
          Icons.all_inclusive,
          Colors.blue,
        ),
        _buildFilterMenuItem('ahorros', 'Ahorros', Icons.savings, Colors.green),
        _buildFilterMenuItem(
          'retiros',
          'Retiros',
          Icons.arrow_circle_down,
          Colors.red,
        ),
        _buildFilterMenuItem(
          'prestamos',
          'Préstamos',
          Icons.credit_card,
          Colors.orange,
        ),
        _buildFilterMenuItem(
          'pagos',
          'Pagos de Préstamos',
          Icons.payment,
          Colors.blue,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _filterType == value ? color : Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (value) => setState(() => _sortBy = value),
      itemBuilder: (context) => [
        _buildSortMenuItem('reciente', 'Más reciente', Icons.arrow_downward),
        _buildSortMenuItem('antigua', 'Más antigua', Icons.arrow_upward),
        _buildSortMenuItem('mayor', 'Mayor monto', Icons.trending_up),
        _buildSortMenuItem('menor', 'Menor monto', Icons.trending_down),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _sortBy == value ? Colors.blue : Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            'Mostrando: ${_getFilterLabel()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _filterType = 'todas'),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  List<TransactionModel> _applyFilters(List<TransactionModel> transactions) {
    // Filtrar por tipo
    if (_filterType != 'todas') {
      transactions = transactions.where((t) {
        switch (_filterType) {
          case 'ahorros':
            return t.tipo == TipoTransaccion.ahorro;
          case 'retiros':
            return t.tipo == TipoTransaccion.retiro;
          case 'prestamos':
            return t.tipo == TipoTransaccion.prestamo;
          case 'pagos':
            return t.tipo == TipoTransaccion.pagoPrestamo;
          default:
            return true;
        }
      }).toList();
    }

    // Ordenar
    switch (_sortBy) {
      case 'reciente':
        transactions.sort((a, b) => b.fecha.compareTo(a.fecha));
        break;
      case 'antigua':
        transactions.sort((a, b) => a.fecha.compareTo(b.fecha));
        break;
      case 'mayor':
        transactions.sort((a, b) => b.monto.compareTo(a.monto));
        break;
      case 'menor':
        transactions.sort((a, b) => a.monto.compareTo(b.monto));
        break;
    }

    return transactions;
  }

  Map<String, double> _calculateTotals(List<TransactionModel> transactions) {
    double totalIngresos = 0;
    double totalEgresos = 0;

    for (var t in transactions) {
      if (t.esIngreso()) {
        totalIngresos += t.monto;
      } else {
        totalEgresos += t.monto;
      }
    }

    return {'ingresos': totalIngresos, 'egresos': totalEgresos};
  }

  String _getFilterLabel() {
    switch (_filterType) {
      case 'ahorros':
        return 'Solo Ahorros';
      case 'retiros':
        return 'Solo Retiros';
      case 'prestamos':
        return 'Solo Préstamos';
      case 'pagos':
        return 'Solo Pagos de Préstamos';
      default:
        return 'Todas';
    }
  }

  Widget _buildSummaryCard(
    Map<String, double> totals,
    NumberFormat currencyFormat,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Resumen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTotalColumn(
                'Ingresos',
                currencyFormat.format(totals['ingresos']),
                Icons.arrow_circle_up,
              ),
              _buildTotalColumn(
                'Egresos',
                currencyFormat.format(totals['egresos']),
                Icons.arrow_circle_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
