import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/loan_service.dart';

// Models
import '../../models/loan_request_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/custom_buttons.dart';

/// ✅ LOAN REQUEST SCREEN - OPTIMIZADO
///
/// Cambios:
/// - ✅ Usa LoanService con Service Locator
/// - ✅ Validaciones mejoradas
/// - ✅ Cálculos en tiempo real
/// - ✅ Mejor UX con feedback visual
class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  // 🎯 Service Locator
  final LoanService _loanService = getIt<LoanService>();

  // Form
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _plazoController = TextEditingController();
  final _tasaController = TextEditingController(text: '5.0');
  final _motivoController = TextEditingController();

  // Estado
  bool _isLoading = false;
  double _montoCuota = 0;
  double _montoTotal = 0;
  double _totalInteres = 0;

  @override
  void dispose() {
    _montoController.dispose();
    _plazoController.dispose();
    _tasaController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  /// Calcula los valores del préstamo en tiempo real
  void _calcularPrestamo() {
    final monto = double.tryParse(_montoController.text) ?? 0;
    final plazo = int.tryParse(_plazoController.text) ?? 0;
    final tasa = double.tryParse(_tasaController.text) ?? 0;

    if (monto > 0 && plazo > 0 && tasa >= 0) {
      setState(() {
        _montoTotal = monto * (1 + (tasa / 100));
        _totalInteres = _montoTotal - monto;
        _montoCuota = _montoTotal / plazo;
      });
    } else {
      setState(() {
        _montoCuota = 0;
        _montoTotal = 0;
        _totalInteres = 0;
      });
    }
  }

  /// Envía la solicitud de préstamo
  Future<void> _submitLoanRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que los cálculos estén listos
    if (_montoCuota <= 0) {
      showErrorSnackbar(context, 'Por favor verifica los datos del préstamo');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null ||
        authProvider.selectedGroup == null) {
      showErrorSnackbar(context, 'Error: Usuario o grupo no encontrado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear solicitud de préstamo
      final loanRequest = LoanRequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        grupoId: authProvider.selectedGroup!.id,
        solicitanteId: authProvider.currentUser!.uid,
        nombreSolicitante: authProvider.currentUser!.nombre,
        montoSolicitado: double.parse(_montoController.text),
        plazoCuotas: int.parse(_plazoController.text),
        tasaInteres: double.parse(_tasaController.text),
        motivo: _motivoController.text.trim(),
        fechaSolicitud: DateTime.now().toUtc(),
        estado: EstadoSolicitud.pendiente,
        votos: [],
      );

      // Guardar usando el servicio
      final result = await _loanService.createLoanRequest(loanRequest);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result.isSuccess) {
        // Mostrar diálogo de éxito
        await _showSuccessDialog(loanRequest);
      } else {
        showErrorSnackbar(
          context,
          result.errorMessage ?? 'Error al crear solicitud',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorSnackbar(context, 'Error inesperado: $e');
      }
      debugPrint('❌ Error al crear solicitud: $e');
    }
  }

  /// Muestra diálogo de éxito con los detalles
  Future<void> _showSuccessDialog(LoanRequestModel loan) async {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('¡Solicitud Enviada!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu solicitud de préstamo ha sido enviada al grupo.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Monto solicitado',
                    currencyFormat.format(loan.montoSolicitado),
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow('Plazo', '${loan.plazoCuotas} meses'),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    'Cuota mensual',
                    currencyFormat.format(loan.montoPorCuota),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los miembros tienen 3 días para votar',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            label: 'Entendido',
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver a dashboard
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Préstamo'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.request_quote,
                    size: 60,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Título
              const Text(
                'Solicitud de Préstamo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Los miembros del grupo votarán tu solicitud',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Campo Monto
              TextFormField(
                controller: _montoController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Solicitado *',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                  hintText: '1000',
                  helperText: 'Ingresa el monto que necesitas',
                ),
                onChanged: (value) => _calcularPrestamo(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el monto';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  if (monto < 50) {
                    return 'El monto mínimo es \$50';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo Plazo
              TextFormField(
                controller: _plazoController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Plazo (meses) *',
                  prefixIcon: Icon(Icons.calendar_month),
                  hintText: '12',
                  helperText: 'Número de cuotas mensuales',
                ),
                onChanged: (value) => _calcularPrestamo(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el plazo';
                  }
                  final plazo = int.tryParse(value);
                  if (plazo == null || plazo <= 0) {
                    return 'Ingresa un plazo válido';
                  }
                  if (plazo < 1) {
                    return 'El plazo mínimo es 1 mes';
                  }
                  if (plazo > 60) {
                    return 'El plazo máximo es 60 meses';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo Tasa de Interés
              TextFormField(
                controller: _tasaController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tasa de Interés (%) *',
                  prefixIcon: Icon(Icons.percent),
                  hintText: '5.0',
                  helperText: 'Interés aplicable al préstamo',
                ),
                onChanged: (value) => _calcularPrestamo(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la tasa';
                  }
                  final tasa = double.tryParse(value);
                  if (tasa == null || tasa < 0) {
                    return 'Ingresa una tasa válida';
                  }
                  if (tasa > 50) {
                    return 'La tasa máxima es 50%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo Motivo
              TextFormField(
                controller: _motivoController,
                enabled: !_isLoading,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Motivo del Préstamo *',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Explica por qué necesitas el préstamo',
                  alignLabelWithHint: true,
                  helperText: 'Sé claro y específico',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el motivo';
                  }
                  if (value.length < 10) {
                    return 'El motivo debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Cálculo de cuotas
              if (_montoCuota > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Resumen del Préstamo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        'Monto solicitado:',
                        currencyFormat.format(
                          double.tryParse(_montoController.text) ?? 0,
                        ),
                      ),
                      _buildSummaryRow(
                        'Interés (${_tasaController.text}%):',
                        currencyFormat.format(_totalInteres),
                      ),
                      const Divider(height: 20),
                      _buildSummaryRow(
                        'Total a pagar:',
                        currencyFormat.format(_montoTotal),
                        isBold: true,
                      ),
                      _buildSummaryRow(
                        'Cuota mensual:',
                        currencyFormat.format(_montoCuota),
                        isBold: true,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Botón Enviar
              PrimaryButton(
                label: 'Enviar Solicitud',
                icon: Icons.send,
                backgroundColor: Colors.orange,
                isLoading: _isLoading,
                onPressed: _submitLoanRequest,
              ),
              const SizedBox(height: 16),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los miembros del grupo votarán para aprobar tu solicitud. '
                        'Se requiere mayoría de votos a favor o que transcurran 3 días.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 15 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: isBold || isHighlighted
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: color ?? (isHighlighted ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }
}
