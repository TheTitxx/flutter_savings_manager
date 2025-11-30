import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/transaction_service.dart';
import '../../services/loan_service.dart';

// Models
import '../../models/transaction_model.dart';
import '../../models/loan_request_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/custom_cards.dart';

// Screens
import 'loan_payment_screen.dart';

/// ✅ PERSONAL DASHBOARD OPTIMIZADO
///
/// Cambios principales:
/// - ✅ Elimina FirebaseService (usa TransactionService y LoanService)
/// - ✅ Usa widgets reutilizables (TransactionCard)
/// - ✅ Separa lógica de UI
/// - ✅ Mejor organización del código
/// - ✅ Manejo consistente de estados
class PersonalDashboardScreen extends StatelessWidget {
  const PersonalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final group = authProvider.selectedGroup;
    final user = authProvider.currentUser;
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    if (group == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Dashboard')),
        body: const EmptyStateWidget(
          icon: Icons.person_off,
          title: 'No hay datos disponibles',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Dashboard Personal'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: authProvider.isPresident
                  ? Colors.orange
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              authProvider.isPresident ? 'PRESIDENTE' : 'MIEMBRO',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => authProvider.syncUserData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 👤 Información del usuario
            _UserInfoCard(user: user, group: group),
            const SizedBox(height: 24),

            // 💰 Resumen financiero personal
            _PersonalFinancialSummary(
              groupId: group.id,
              userId: user.uid,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 24),

            // 💳 Mis préstamos activos
            _MyActiveLoansSection(
              groupId: group.id,
              userId: user.uid,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: 24),

            // 🧾 Mis últimas transacciones
            SectionHeader(
              title: 'Mis Últimas Transacciones',
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 12),
            _MyRecentTransactions(
              groupId: group.id,
              userId: user.uid,
              currencyFormat: currencyFormat,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== USER INFO CARD ====================

class _UserInfoCard extends StatelessWidget {
  final dynamic user;
  final dynamic group;

  const _UserInfoCard({required this.user, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Text(
                user.nombre[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    'Grupo: ${group.nombre}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PERSONAL FINANCIAL SUMMARY ====================

class _PersonalFinancialSummary extends StatelessWidget {
  final String groupId;
  final String userId;
  final NumberFormat currencyFormat;

  const _PersonalFinancialSummary({
    required this.groupId,
    required this.userId,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final transactionService = getIt<TransactionService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: transactionService
          .getUserTransactionStats(groupId, userId)
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

        final stats = snapshot.data ?? {};
        final misAhorros = stats['ahorros'] ?? 0.0;
        final misRetiros = stats['retiros'] ?? 0.0;
        final saldoPersonal = stats['saldoNeto'] ?? 0.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi Resumen Financiero',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildFinancialItem(
                  'Mis Ahorros',
                  currencyFormat.format(misAhorros),
                  Icons.savings,
                ),
                const Divider(color: Colors.white30, height: 30),
                _buildFinancialItem(
                  'Mis Retiros',
                  currencyFormat.format(misRetiros),
                  Icons.arrow_circle_down,
                ),
                const Divider(color: Colors.white30, height: 30),
                _buildFinancialItem(
                  'Mi Saldo',
                  currencyFormat.format(saldoPersonal),
                  Icons.account_balance_wallet,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialItem(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ==================== MY ACTIVE LOANS SECTION ====================

class _MyActiveLoansSection extends StatelessWidget {
  final String groupId;
  final String userId;
  final NumberFormat currencyFormat;

  const _MyActiveLoansSection({
    required this.groupId,
    required this.userId,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final loanService = getIt<LoanService>();

    return StreamBuilder<List<LoanRequestModel>>(
      stream: loanService.getGroupLoanRequests(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final allLoans = snapshot.data ?? [];

        // 🔥 Incluir PENDIENTES y APROBADOS
        final misPrestamos = allLoans
            .where(
              (loan) =>
                  loan.solicitanteId == userId &&
                  (loan.estado == EstadoSolicitud.pendiente ||
                      loan.estado == EstadoSolicitud.aprobada) &&
                  !loan.estaPagado,
            )
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Mis Préstamos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (misPrestamos.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No tienes préstamos activos',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...misPrestamos.map(
                    (loan) => _buildLoanCard(context, loan, currencyFormat),
                  ),

                // Botón para gestionar pagos (solo si hay aprobados)
                if (misPrestamos.any(
                  (l) => l.estado == EstadoSolicitud.aprobada,
                )) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoanPaymentScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Gestionar Pagos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    LoanRequestModel loan,
    NumberFormat currencyFormat,
  ) {
    final porcentajePagado = loan.estado == EstadoSolicitud.aprobada
        ? (loan.montoPagado / loan.montoTotalConInteres) * 100
        : 0.0;

    // Determinar color y estado
    Color colorEstado = Colors.blue;
    String textoEstado = "En votación";
    IconData iconoEstado = Icons.hourglass_empty;

    if (loan.estado == EstadoSolicitud.aprobada) {
      colorEstado = Colors.orange;
      textoEstado = "Pagando - ${porcentajePagado.toStringAsFixed(0)}%";
      iconoEstado = Icons.attach_money;
    }

    return Card(
      color: colorEstado == Colors.blue
          ? Colors.blue.shade50
          : Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(loan.montoSolicitado),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.orange,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorEstado,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconoEstado, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        textoEstado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${loan.motivo}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Información según estado
            if (loan.estado == EstadoSolicitud.pendiente) ...[
              // EN VOTACIÓN
              _buildVotingInfo(loan),
            ] else if (loan.estado == EstadoSolicitud.aprobada) ...[
              // APROBADO
              _buildPaymentInfo(loan, currencyFormat, porcentajePagado),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVotingInfo(LoanRequestModel loan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estado de Votación:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${loan.diasRestantes()} días restantes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVoteColumn(
                Icons.thumb_up,
                '${loan.votosAFavor}',
                Colors.green,
              ),
              _buildVoteColumn(
                Icons.thumb_down,
                '${loan.votosEnContra}',
                Colors.red,
              ),
              _buildVoteColumn(Icons.people, '${loan.totalVotos}', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteColumn(IconData icon, String count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(
    LoanRequestModel loan,
    NumberFormat currencyFormat,
    double porcentajePagado,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuotas: ${loan.plazoCuotas} meses',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Cuota: ${currencyFormat.format(loan.montoPorCuota)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Por pagar:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  currencyFormat.format(loan.saldoPendiente),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentajePagado / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

// ==================== MY RECENT TRANSACTIONS ====================

class _MyRecentTransactions extends StatelessWidget {
  final String groupId;
  final String userId;
  final NumberFormat currencyFormat;

  const _MyRecentTransactions({
    required this.groupId,
    required this.userId,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final transactionService = getIt<TransactionService>();

    return StreamBuilder<List<TransactionModel>>(
      stream: transactionService.getUserTransactions(groupId, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Cargando transacciones...');
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            message: 'Error al cargar transacciones',
            onRetry: () {},
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long,
            title: 'No tienes transacciones aún',
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 10 ? 10 : transactions.length,
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
        );
      },
    );
  }
}
