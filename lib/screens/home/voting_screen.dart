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

/// ✅ VOTING SCREEN - OPTIMIZADO
///
/// Cambios principales:
/// - ✅ Usa LoanService con Service Locator
/// - ✅ Usa LoanCard reutilizable
/// - ✅ Mejor manejo de estados
/// - ✅ Separación de responsabilidades
class VotingScreen extends StatelessWidget {
  const VotingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final group = authProvider.selectedGroup;
    final user = authProvider.currentUser;
    final loanService = getIt<LoanService>();
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    if (group == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Votaciones')),
        body: const EmptyStateWidget(
          icon: Icons.how_to_vote,
          title: 'No hay datos disponibles',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votaciones Pendientes'),
        actions: [
          // Badge con número de votaciones pendientes
          StreamBuilder<List<LoanRequestModel>>(
            stream: loanService.getPendingLoanRequests(group.id),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              if (count == 0) return const SizedBox.shrink();

              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count pendiente${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LoanRequestModel>>(
        stream: loanService.getPendingLoanRequests(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Cargando votaciones...');
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: 'Error al cargar votaciones',
              onRetry: () {},
            );
          }

          final solicitudes = snapshot.data ?? [];

          if (solicitudes.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // El stream se actualiza automáticamente
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final solicitud = solicitudes[index];
                return _buildVotingCard(
                  context,
                  solicitud,
                  user.uid,
                  user.nombre,
                  group.numeroMiembros,
                  authProvider.isPresident,
                  loanService,
                  currencyFormat,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.how_to_vote,
      title: 'No hay solicitudes pendientes',
      subtitle:
          'Cuando alguien solicite un préstamo,\naparecerá aquí para votar',
    );
  }

  // ==================== VOTING CARD ====================

  Widget _buildVotingCard(
    BuildContext context,
    LoanRequestModel solicitud,
    String currentUserId,
    String currentUserName,
    int totalMiembros,
    bool isPresident,
    LoanService loanService,
    NumberFormat currencyFormat,
  ) {
    final yaVote = solicitud.usuarioYaVoto(currentUserId);
    final esMiSolicitud = solicitud.solicitanteId == currentUserId;
    final diasRestantes = solicitud.diasRestantes();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header con solicitante y tiempo restante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.orange,
                      child: Text(
                        solicitud.nombreSolicitante[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  solicitud.nombreSolicitante,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (esMiSolicitud)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'TU SOLICITUD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Solicitó el ${DateFormat('dd/MM/yyyy').format(solicitud.fechaSolicitud)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tiempo restante
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: diasRestantes > 0
                        ? Colors.blue.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: diasRestantes > 0
                          ? Colors.blue.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: diasRestantes > 0
                            ? Colors.blue.shade700
                            : Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          diasRestantes > 0
                              ? 'Tiempo restante: $diasRestantes ${diasRestantes == 1 ? 'día' : 'días'}'
                              : 'Votación cerrada por tiempo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: diasRestantes > 0
                                ? Colors.blue.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detalles del préstamo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto, plazo, interés
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailColumn(
                      'Monto',
                      currencyFormat.format(solicitud.montoSolicitado),
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildDetailColumn(
                      'Plazo',
                      '${solicitud.plazoCuotas} meses',
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                    _buildDetailColumn(
                      'Interés',
                      '${solicitud.tasaInteres}%',
                      Icons.percent,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailColumn(
                  'Cuota',
                  currencyFormat.format(solicitud.montoPorCuota),
                  Icons.payment,
                  Colors.purple,
                ),
                const Divider(height: 24),

                // Motivo
                const Text(
                  'Motivo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    solicitud.motivo,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
                const Divider(height: 24),

                // Votos actuales
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Estado de Votación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildVoteColumn(
                            'A favor',
                            solicitud.votosAFavor,
                            Icons.thumb_up,
                            Colors.green,
                          ),
                          _buildVoteColumn(
                            'En contra',
                            solicitud.votosEnContra,
                            Icons.thumb_down,
                            Colors.red,
                          ),
                          _buildVoteColumn(
                            'Total',
                            solicitud.totalVotos,
                            Icons.people,
                            Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value:
                            solicitud.totalVotos /
                            (totalMiembros - 1).clamp(1, totalMiembros),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${solicitud.totalVotos} de ${totalMiembros - 1} votos',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botones de votación
                if (!esMiSolicitud && !yaVote)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showVoteConfirmation(
                            context,
                            solicitud,
                            true,
                            currentUserName,
                            loanService,
                            totalMiembros,
                          ),
                          icon: const Icon(Icons.thumb_up, size: 20),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showVoteConfirmation(
                            context,
                            solicitud,
                            false,
                            currentUserName,
                            loanService,
                            totalMiembros,
                          ),
                          icon: const Icon(Icons.thumb_down, size: 20),
                          label: const Text('Rechazar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (yaVote)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.blue, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Ya votaste en esta solicitud',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'No puedes votar tu propia solicitud',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Acciones del presidente
                if (isPresident && !esMiSolicitud) ...[
                  const Divider(height: 24),
                  const Text(
                    'Acciones de Presidente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cerrarVotacionManual(
                            context,
                            solicitud.id,
                            true,
                            loanService,
                          ),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            'Aprobar Ahora',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cerrarVotacionManual(
                            context,
                            solicitud.id,
                            false,
                            loanService,
                          ),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text(
                            'Rechazar Ahora',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _buildDetailColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteColumn(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ==================== DIALOGS ====================

  void _showVoteConfirmation(
    BuildContext context,
    LoanRequestModel solicitud,
    bool aprobo,
    String nombreUsuario,
    LoanService loanService,
    int totalMiembros,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              aprobo ? Icons.thumb_up : Icons.thumb_down,
              color: aprobo ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(aprobo ? '¿Aprobar préstamo?' : '¿Rechazar préstamo?'),
          ],
        ),
        content: Text(
          aprobo
              ? '¿Estás seguro de que quieres aprobar esta solicitud de préstamo?'
              : '¿Estás seguro de que quieres rechazar esta solicitud de préstamo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Cerrar diálogo de confirmación
              Navigator.pop(context);

              // ✅ GUARDAR REFERENCIA AL NAVIGATOR
              final navigator = Navigator.of(context);

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Registrando voto...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                final result = await loanService.voteOnLoan(
                  loanRequestId: solicitud.id,
                  userId: authProvider.currentUser!.uid,
                  nombreUsuario: nombreUsuario,
                  aprobo: aprobo,
                  totalMiembros: totalMiembros,
                );

                // ✅ CERRAR LOADING SIEMPRE (usando navigator guardado)
                navigator.pop();

                // ✅ VERIFICAR mounted ANTES de usar context
                if (!context.mounted) return;

                if (result.isSuccess) {
                  showSuccessSnackbar(
                    context,
                    '✅ ¡Voto registrado exitosamente!',
                  );
                } else {
                  showErrorSnackbar(
                    context,
                    result.errorMessage ?? 'Error al registrar el voto',
                  );
                }
              } catch (e) {
                // ✅ CERRAR LOADING EN CASO DE ERROR
                navigator.pop();

                if (context.mounted) {
                  showErrorSnackbar(context, '❌ Error inesperado: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: aprobo ? Colors.green : Colors.red,
            ),
            child: Text(aprobo ? 'Sí, aprobar' : 'Sí, rechazar'),
          ),
        ],
      ),
    );
  }

  void _cerrarVotacionManual(
    BuildContext context,
    String loanRequestId,
    bool aprobar,
    LoanService loanService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Votación'),
        content: Text(
          aprobar
              ? '¿Estás seguro de aprobar este préstamo como presidente?\n\nEsto cerrará la votación inmediatamente.'
              : '¿Estás seguro de rechazar este préstamo como presidente?\n\nEsto cerrará la votación inmediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // ✅ GUARDAR REFERENCIA AL NAVIGATOR
              final navigator = Navigator.of(context);

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cerrando votación...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final result = await loanService.cerrarVotacionManual(
                  loanRequestId,
                  aprobar,
                );

                // ✅ CERRAR LOADING SIEMPRE
                navigator.pop();

                if (!context.mounted) return;

                if (result.isSuccess) {
                  showSuccessSnackbar(
                    context,
                    '✅ Votación cerrada exitosamente',
                  );
                } else {
                  showErrorSnackbar(
                    context,
                    result.errorMessage ?? 'Error al cerrar votación',
                  );
                }
              } catch (e) {
                // ✅ CERRAR LOADING EN CASO DE ERROR
                navigator.pop();

                if (context.mounted) {
                  showErrorSnackbar(context, '❌ Error inesperado: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: aprobar ? Colors.green : Colors.red,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
