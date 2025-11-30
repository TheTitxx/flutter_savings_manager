import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 🗨️ DIÁLOGOS REUTILIZABLES
///
/// Ventajas:
/// ✅ Reducción de código duplicado
/// ✅ Validaciones centralizadas
/// ✅ UX consistente en toda la app

// ==================== TRANSACTION DIALOG ====================

/// Diálogo para agregar ahorros o retiros
class TransactionDialog extends StatefulWidget {
  final bool isWithdrawal; // true = retiro, false = ahorro
  final double? maxAmount; // límite para retiros
  final Function(double amount, String description) onConfirm;

  const TransactionDialog({
    super.key,
    this.isWithdrawal = false,
    this.maxAmount,
    required this.onConfirm,
  });

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isWithdrawal
        ? '💸 Retirar Ahorro'
        : '💰 Agregar Ahorro';
    final color = widget.isWithdrawal ? Colors.red : Colors.green;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isWithdrawal ? Icons.arrow_circle_down : Icons.add_circle,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar saldo disponible para retiros
              if (widget.isWithdrawal && widget.maxAmount != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saldo disponible:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                symbol: '\$',
                                decimalDigits: 2,
                              ).format(widget.maxAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo de monto
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: !_isProcessing,
                decoration: InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money, color: color),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un monto';
                  }

                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }

                  // Validar que no exceda el saldo disponible
                  if (widget.isWithdrawal &&
                      widget.maxAmount != null &&
                      amount > widget.maxAmount!) {
                    return 'Saldo insuficiente';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de descripción
              TextFormField(
                controller: _descriptionController,
                enabled: !_isProcessing,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción *',
                  hintText: widget.isWithdrawal
                      ? 'Motivo del retiro'
                      : 'Concepto del ahorro',
                  prefixIcon: const Icon(Icons.description),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  if (value.length < 5) {
                    return 'Mínimo 5 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.isWithdrawal ? 'Retirar' : 'Ahorrar'),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      await widget.onConfirm(amount, description);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

// ==================== PAYMENT DIALOG ====================

/// Diálogo especializado para pagos de préstamos
class PaymentDialog extends StatefulWidget {
  final double saldoPendiente;
  final double montoCuota;
  final Function(double amount, String description) onConfirm;

  const PaymentDialog({
    super.key,
    required this.saldoPendiente,
    required this.montoCuota,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Sugerir el monto de la cuota
    _descriptionController.text =
        'Pago de cuota - Préstamo ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(widget.saldoPendiente)}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payment, color: Colors.green),
          SizedBox(width: 8),
          Text('💳 Realizar Pago'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info del préstamo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saldo pendiente:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currencyFormat.format(widget.saldoPendiente),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cuota sugerida:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          currencyFormat.format(widget.montoCuota),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo de monto
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                enabled: !_isProcessing,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar *',
                  prefixText: '\$ ',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un monto';
                  }

                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Monto inválido';
                  }

                  // ⚠️ VALIDACIÓN: No exceder saldo pendiente
                  if (amount > (widget.saldoPendiente + 0.01)) {
                    return 'No puede exceder el saldo pendiente';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Botones rápidos
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickAmountChip('Cuota', widget.montoCuota),
                  _buildQuickAmountChip('Mitad', widget.saldoPendiente / 2),
                  _buildQuickAmountChip('Total', widget.saldoPendiente),
                ],
              ),
              const SizedBox(height: 16),

              // Campo de descripción
              TextFormField(
                controller: _descriptionController,
                enabled: !_isProcessing,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Pagar'),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return ActionChip(
      label: Text(
        '$label: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount)}',
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: _isProcessing
          ? null
          : () {
              _amountController.text = amount.toStringAsFixed(2);
            },
    );
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      await widget.onConfirm(amount, description);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

// ==================== CONFIRMATION DIALOG ====================

/// Diálogo de confirmación genérico reutilizable
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final bool isDangerous;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
    this.isDangerous = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = confirmColor ?? (isDangerous ? Colors.red : Colors.blue);

    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

// ==================== INFO DIALOG ====================

/// Diálogo informativo simple
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

// ==================== HELPERS ====================

/// Muestra un diálogo de transacción
Future<bool?> showTransactionDialog(
  BuildContext context, {
  required bool isWithdrawal,
  double? maxAmount,
  required Function(double amount, String description) onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TransactionDialog(
      isWithdrawal: isWithdrawal,
      maxAmount: maxAmount,
      onConfirm: onConfirm,
    ),
  );
}

/// Muestra un diálogo de pago
Future<bool?> showPaymentDialog(
  BuildContext context, {
  required double saldoPendiente,
  required double montoCuota,
  required Function(double amount, String description) onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PaymentDialog(
      saldoPendiente: saldoPendiente,
      montoCuota: montoCuota,
      onConfirm: onConfirm,
    ),
  );
}

/// Muestra un diálogo de confirmación
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String cancelText = 'Cancelar',
  Color? confirmColor,
  bool isDangerous = false,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      isDangerous: isDangerous,
      icon: icon,
    ),
  );
}

/// Muestra un diálogo informativo
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.info_outline,
  Color color = Colors.blue,
}) {
  return showDialog(
    context: context,
    builder: (context) =>
        InfoDialog(title: title, message: message, icon: icon, color: color),
  );
}
