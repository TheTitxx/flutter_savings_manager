import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';
import '../../services/loan_service.dart';
import '../../models/loan_request_model.dart';
import '../../models/loan_payment_model.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/dialogs/custom_dialogs.dart';

class LoanPaymentScreen extends StatelessWidget {
  const LoanPaymentScreen({super.key});

  LoanService get _loanService => getIt<LoanService>();

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
        appBar: AppBar(title: const Text('Mis Préstamos')),
        body: const EmptyStateWidget(
          icon: Icons.credit_card,
          title: 'No hay datos disponibles',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar Préstamos')),
      body: StreamBuilder<List<LoanRequestModel>>(
        stream: _loanService.getMyActiveLoans(group.id, user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Cargando préstamos...');
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: 'Error al cargar préstamos',
              onRetry: () {},
            );
          }

          final loans = snapshot.data ?? [];

          if (loans.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.check_circle_outline,
              title: 'No tienes préstamos activos',
              subtitle: '¡Estás al día con tus pagos!',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecciona un préstamo para realizar un pago',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...loans.map(
                (loan) =>
                    _buildLoanCard(loan, currencyFormat, context, user.uid),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(
    LoanRequestModel loan,
    NumberFormat currencyFormat,
    BuildContext context,
    String userId,
  ) {
    final porcentajePagado =
        (loan.montoPagado / loan.montoTotalConInteres) * 100;
    final cuotasPagadas = (loan.montoPagado / loan.montoPorCuota).floor();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(loan.montoSolicitado),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Préstamo solicitado',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${porcentajePagado.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motivo: ${loan.motivo}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      'Total a Pagar',
                      currencyFormat.format(loan.montoTotalConInteres),
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                    _buildInfoColumn(
                      'Ya Pagado',
                      currencyFormat.format(loan.montoPagado),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildInfoColumn(
                      'Pendiente',
                      currencyFormat.format(loan.saldoPendiente),
                      Icons.pending,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso del pago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$cuotasPagadas de ${loan.plazoCuotas} cuotas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: porcentajePagado / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCuotaInfo(
                        '${loan.plazoCuotas} meses',
                        'Plazo',
                        Icons.calendar_month,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildCuotaInfo(
                        currencyFormat.format(loan.montoPorCuota),
                        'Por cuota',
                        Icons.payment,
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildCuotaInfo(
                        '${loan.tasaInteres}%',
                        'Interés',
                        Icons.percent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(
                          context,
                          loan,
                          currencyFormat,
                          userId,
                        ),
                        icon: const Icon(Icons.payment),
                        label: const Text('Hacer Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showPaymentHistory(context, loan, currencyFormat),
                        icon: const Icon(Icons.history, size: 20),
                        label: const Text('Historial'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCuotaInfo(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    LoanRequestModel loan,
    NumberFormat currencyFormat,
    String userId,
  ) {
    showPaymentDialog(
      context,
      saldoPendiente: loan.saldoPendiente,
      montoCuota: loan.montoPorCuota,
      onConfirm: (amount, description) async {
        final loanService = getIt<LoanService>();
        final result = await loanService.registerLoanPayment(
          loanRequestId: loan.id,
          userId: userId,
          montoPago: amount,
          descripcion: description,
        );

        if (context.mounted) {
          if (result.isSuccess) {
            showSuccessSnackbar(context, '✅ ¡Pago registrado exitosamente!');
          } else {
            showErrorSnackbar(
              context,
              result.errorMessage ?? 'Error al registrar el pago',
            );
          }
        }
      },
    );
  }

  void _showPaymentHistory(
    BuildContext context,
    LoanRequestModel loan,
    NumberFormat currencyFormat,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Historial de Pagos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<LoanPaymentModel>>(
                stream: _loanService.getLoanPayments(loan.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(
                      message: 'Cargando historial...',
                    );
                  }

                  final payments = snapshot.data ?? [];

                  if (payments.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.receipt_long,
                      title: 'No hay pagos registrados aún',
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(
                              '${payment.numeroCuota}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          title: Text(
                            currencyFormat.format(payment.montoPagado),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.descripcion,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(payment.fechaPago),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
