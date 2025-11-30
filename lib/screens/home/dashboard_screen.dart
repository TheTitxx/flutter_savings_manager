import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/transaction_service.dart';
import '../../services/loan_service.dart';
import '../../services/meeting_service.dart';

// Models
import '../../models/transaction_model.dart';
import '../../models/meeting_model.dart';

// Widgets reutilizables
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/custom_buttons.dart';
import '../../widgets/cards/custom_cards.dart';
import '../../widgets/dialogs/custom_dialogs.dart';

// Screens
import 'personal_dashboard_screen.dart';
import 'loan_request_screen.dart';
import 'reports_screen.dart';
import 'voting_screen.dart';
import 'members_screen.dart';
import 'all_transactions_screen.dart';
import 'meetings_screen.dart';
import 'create_meeting_screen.dart';

/// ✅ DASHBOARD OPTIMIZADO
///
/// Cambios principales:
/// - ✅ Usa TransactionService para crear transacciones
/// - ✅ Integra custom_dialogs.dart
/// - ✅ Elimina código duplicado
/// - ✅ Mejor manejo de errores
/// - ✅ Separación de responsabilidades
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final group = authProvider.selectedGroup;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const EmptyStateWidget(
          icon: Icons.group_off,
          title: 'No hay grupo seleccionado',
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, authProvider),
      body: RefreshIndicator(
        onRefresh: () => authProvider.syncUserData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 💰 Resumen Financiero
            _FinancialSummarySection(groupId: group.id),
            const SizedBox(height: 24),

            // 📅 Próximas Reuniones
            _UpcomingMeetingsSection(groupId: group.id),
            const SizedBox(height: 24),

            // ⚡ Acciones Rápidas
            SectionHeader(title: 'Acciones Rápidas', icon: Icons.flash_on),
            const SizedBox(height: 12),
            _QuickActionsGrid(
              groupId: group.id,
              userId: authProvider.currentUser!.uid,
              isPresident: authProvider.isPresident,
            ),
            const SizedBox(height: 24),

            // 🧾 Transacciones Recientes
            SectionHeader(
              title: 'Transacciones Recientes',
              actionText: 'Ver todas',
              onActionTap: () =>
                  _navigateTo(context, const AllTransactionsScreen()),
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 12),
            _RecentTransactionsSection(groupId: group.id),
          ],
        ),
      ),
      floatingActionButton: authProvider.isPresident
          ? CustomFAB(
              icon: Icons.event_available,
              label: 'Nueva Reunión',
              onPressed: () =>
                  _navigateTo(context, const CreateMeetingScreen()),
            )
          : null,
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return AppBar(
      title: Text(authProvider.selectedGroup?.nombre ?? 'Dashboard'),
      actions: [
        // Botón de Reuniones
        IconButton(
          icon: const Icon(Icons.event),
          tooltip: 'Reuniones',
          onPressed: () => _navigateTo(context, const MeetingsScreen()),
        ),

        // Botón de Votaciones con badge
        _VotingButton(
          groupId: authProvider.selectedGroup!.id,
          onPressed: () => _navigateTo(context, const VotingScreen()),
        ),

        // Badge de presidente
        if (authProvider.isPresident)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'PRESIDENTE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== NAVEGACIÓN ====================

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

// ==================== SECCIÓN: RESUMEN FINANCIERO ====================

class _FinancialSummarySection extends StatelessWidget {
  final String groupId;

  const _FinancialSummarySection({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final group = authProvider.selectedGroup!;
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final loanService = getIt<LoanService>();

    return FutureBuilder<double>(
      future: loanService
          .getPrestamosActivosTotal(groupId)
          .then((r) => r.data ?? 0.0),
      builder: (context, snapshot) {
        final prestamosActivos = snapshot.data ?? group.totalPrestamos;

        return FinancialSummaryCard(
          title: 'Resumen Financiero',
          items: [
            FinancialItem(
              label: 'Total Ahorros',
              value: currencyFormat.format(group.totalAhorros),
              icon: Icons.account_balance_wallet,
            ),
            FinancialItem(
              label: 'Préstamos Activos',
              value: currencyFormat.format(prestamosActivos),
              icon: Icons.credit_card,
            ),
            FinancialItem(
              label: 'Miembros',
              value: '${group.numeroMiembros}',
              icon: Icons.people,
            ),
            FinancialItem(
              label: 'Código',
              value: group.codigoInvitacion,
              icon: Icons.vpn_key,
            ),
          ],
        );
      },
    );
  }
}

// ==================== SECCIÓN: PRÓXIMAS REUNIONES ====================

class _UpcomingMeetingsSection extends StatelessWidget {
  final String groupId;

  const _UpcomingMeetingsSection({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final meetingService = getIt<MeetingService>();

    return StreamBuilder<List<MeetingModel>>(
      stream: meetingService.getActiveMeetings(groupId),
      builder: (context, snapshot) {
        final reuniones = snapshot.data ?? [];

        if (reuniones.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Próximas Reuniones',
              actionText: 'Ver todas',
              onActionTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeetingsScreen()),
              ),
              icon: Icons.event,
            ),
            const SizedBox(height: 12),
            ...reuniones.take(3).map((meeting) {
              return MeetingCard(
                titulo: meeting.titulo,
                fechaHora: meeting.fechaHora,
                creadoPor: meeting.creadoPorNombre,
                descripcion: meeting.descripcion,
                esNueva: meeting.esNueva,
                activa: meeting.activa,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeetingsScreen()),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ==================== SECCIÓN: ACCIONES RÁPIDAS ====================

class _QuickActionsGrid extends StatelessWidget {
  final String groupId;
  final String userId;
  final bool isPresident;

  const _QuickActionsGrid({
    required this.groupId,
    required this.userId,
    required this.isPresident,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primera fila
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: 'Agregar Ahorro',
                icon: Icons.add_circle,
                color: Colors.green,
                onTap: () => _handleAddSavings(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                label: 'Retirar Ahorro',
                icon: Icons.remove_circle,
                color: Colors.red,
                onTap: () => _handleWithdrawal(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Segunda fila
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: 'Solicitar Préstamo',
                icon: Icons.request_quote,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanRequestScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isPresident
                  ? ActionButton(
                      label: 'Ver Miembros',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MembersScreen(),
                        ),
                      ),
                    )
                  : ActionButton(
                      label: 'Mi Dashboard',
                      icon: Icons.person,
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalDashboardScreen(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tercera fila
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: 'Reportes',
                icon: Icons.bar_chart,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isPresident
                  ? ActionButton(
                      label: 'Mi Dashboard',
                      icon: Icons.person,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalDashboardScreen(),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== HANDLERS DE ACCIONES ====================

  /// ✅ OPTIMIZADO: Usar custom_dialogs + TransactionService
  Future<void> _handleAddSavings(BuildContext context) async {
    // ✅ AGREGAR VERIFICACIÓN mounted
    if (!context.mounted) return;

    final result = await showTransactionDialog(
      context,
      isWithdrawal: false,
      onConfirm: (amount, description) async {
        await _createTransaction(
          context,
          amount: amount,
          description: description,
          tipo: TipoTransaccion.ahorro,
        );
      },
    );

    if (result == true && context.mounted) {
      // Recargar datos del grupo
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.syncUserData();
    }
  }

  /// ✅ OPTIMIZADO: Validar saldo antes de retirar
  Future<void> _handleWithdrawal(BuildContext context) async {
    final transactionService = getIt<TransactionService>();

    // 1. Obtener estadísticas del usuario para validar saldo
    final statsResult = await transactionService.getUserTransactionStats(
      groupId,
      userId,
    );

    if (statsResult.isFailure) {
      if (context.mounted) {
        showErrorSnackbar(context, statsResult.errorMessage!);
      }
      return;
    }

    final saldoDisponible = statsResult.data!['saldoNeto'] as double;

    if (saldoDisponible <= 0) {
      if (context.mounted) {
        showErrorSnackbar(
          context,
          '⚠️ No tienes saldo disponible para retirar',
        );
      }
      return;
    }

    // ✅ AGREGAR VERIFICACIÓN mounted ANTES de usar context
    if (!context.mounted) return;

    // 2. Mostrar diálogo con validación de saldo
    final result = await showTransactionDialog(
      context,
      isWithdrawal: true,
      maxAmount: saldoDisponible,
      onConfirm: (amount, description) async {
        await _createTransaction(
          context,
          amount: amount,
          description: description,
          tipo: TipoTransaccion.retiro,
        );
      },
    );

    if (result == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.syncUserData();
    }
  }

  /// ✅ NUEVA: Método centralizado para crear transacciones
  Future<void> _createTransaction(
    BuildContext context, {
    required double amount,
    required String description,
    required TipoTransaccion tipo,
  }) async {
    final transactionService = getIt<TransactionService>();

    // Crear transacción
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      grupoId: groupId,
      userId: userId,
      tipo: tipo,
      monto: amount,
      fecha: DateTime.now().toUtc(),
      descripcion: description,
    );

    // Guardar en Firestore
    final result = await transactionService.createTransaction(transaction);

    if (context.mounted) {
      if (result.isSuccess) {
        final mensaje = tipo == TipoTransaccion.ahorro
            ? '✅ Ahorro agregado: \$${amount.toStringAsFixed(2)}'
            : '✅ Retiro realizado: \$${amount.toStringAsFixed(2)}';

        showSuccessSnackbar(context, mensaje);
      } else {
        showErrorSnackbar(
          context,
          result.errorMessage ?? '❌ Error al crear transacción',
        );
      }
    }
  }
}

// ==================== SECCIÓN: TRANSACCIONES RECIENTES ====================

class _RecentTransactionsSection extends StatelessWidget {
  final String groupId;

  const _RecentTransactionsSection({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final transactionService = getIt<TransactionService>();

    return StreamBuilder<List<TransactionModel>>(
      stream: transactionService.getGroupTransactions(groupId),
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
            title: 'No hay transacciones aún',
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length > 5 ? 5 : transactions.length,
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

// ==================== BOTÓN DE VOTACIONES CON BADGE ====================

class _VotingButton extends StatelessWidget {
  final String groupId;
  final VoidCallback onPressed;

  const _VotingButton({required this.groupId, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final loanService = getIt<LoanService>();

    return StreamBuilder<List>(
      stream: loanService.getPendingLoanRequests(groupId),
      builder: (context, snapshot) {
        final pendientes = snapshot.data ?? [];

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.how_to_vote),
              onPressed: onPressed,
            ),
            if (pendientes.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${pendientes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
