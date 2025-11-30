import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/meeting_service.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';

// Models
import '../../models/meeting_model.dart';
import '../../models/group_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/custom_buttons.dart';

/// ✅ MEETING DETAIL SCREEN - OPTIMIZADO
///
/// Cambios principales:
/// - ✅ Usa MeetingService con Service Locator
/// - ✅ Usa GroupService y AuthService
/// - ✅ Elimina FirebaseService
/// - ✅ Usa widgets reutilizables
/// - ✅ Mejor organización del código
/// - ✅ Manejo de estados mejorado
class MeetingDetailScreen extends StatefulWidget {
  final MeetingModel meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  // 🎯 Service Locator
  final MeetingService _meetingService = getIt<MeetingService>();
  final GroupService _groupService = getIt<GroupService>();
  final AuthService _authService = getIt<AuthService>();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isPresident = authProvider.isPresident;

    final dateFormat = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Reunión'),
        backgroundColor: _getStatusColor(widget.meeting.estado),
      ),
      body: StreamBuilder<MeetingModel>(
        stream: _meetingService
            .getMeetingById(widget.meeting.id)
            .asStream()
            .asyncMap((result) => result.data!),
        builder: (context, snapshot) {
          final meeting = snapshot.data ?? widget.meeting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🎯 ESTADO DE LA REUNIÓN
                _StatusCard(meeting: meeting),
                const SizedBox(height: 24),

                // 📋 INFORMACIÓN BÁSICA
                _InfoSection(
                  meeting: meeting,
                  dateFormat: dateFormat,
                  timeFormat: timeFormat,
                ),
                const SizedBox(height: 24),

                // 👁️ NOTIFICACIONES (Solo presidente)
                if (isPresident)
                  _NotificationsSection(
                    meeting: meeting,
                    groupService: _groupService,
                    authService: _authService,
                  ),
                const SizedBox(height: 24),

                // ✅ ASISTENCIA
                if (meeting.horaInicio != null || meeting.finalizada)
                  _AttendanceSection(
                    meeting: meeting,
                    userId: user?.uid,
                    isPresident: isPresident,
                    groupService: _groupService,
                    authService: _authService,
                    meetingService: _meetingService,
                    onAttendanceChanged: () => setState(() {}),
                  ),
                const SizedBox(height: 24),

                // ⏱️ TIEMPOS
                if (meeting.horaInicio != null)
                  _TimesSection(meeting: meeting, timeFormat: timeFormat),
                const SizedBox(height: 24),

                // 🎬 BOTONES DE ACCIÓN (PRESIDENTE)
                if (isPresident && !meeting.finalizada && meeting.activa)
                  _PresidentActions(
                    meeting: meeting,
                    isLoading: _isLoading,
                    meetingService: _meetingService,
                    onLoadingChanged: (loading) =>
                        setState(() => _isLoading = loading),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Finalizada':
        return Colors.grey;
      case 'Cancelada':
        return Colors.red;
      case 'En curso':
        return Colors.green;
      case 'No iniciada':
        return Colors.orange;
      case 'Programada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// ==================== STATUS CARD ====================

class _StatusCard extends StatelessWidget {
  final MeetingModel meeting;

  const _StatusCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getStatusColor(meeting.estado).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(meeting.estado),
              size: 40,
              color: _getStatusColor(meeting.estado),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estado: ${meeting.estado}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getStatusColor(meeting.estado),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Finalizada':
        return Colors.grey;
      case 'Cancelada':
        return Colors.red;
      case 'En curso':
        return Colors.green;
      case 'No iniciada':
        return Colors.orange;
      case 'Programada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'Finalizada':
        return Icons.check_circle;
      case 'Cancelada':
        return Icons.cancel;
      case 'En curso':
        return Icons.play_circle;
      case 'No iniciada':
        return Icons.warning;
      case 'Programada':
        return Icons.schedule;
      default:
        return Icons.event;
    }
  }
}

// ==================== INFO SECTION ====================

class _InfoSection extends StatelessWidget {
  final MeetingModel meeting;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const _InfoSection({
    required this.meeting,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.calendar_today,
              'Fecha',
              dateFormat.format(meeting.fechaHora),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time,
              'Hora programada',
              timeFormat.format(meeting.fechaHora),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.person,
              'Creado por',
              meeting.creadoPorNombre,
            ),
            if (meeting.descripcion != null &&
                meeting.descripcion!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Descripción:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                meeting.descripcion!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ==================== NOTIFICATIONS SECTION ====================

class _NotificationsSection extends StatelessWidget {
  final MeetingModel meeting;
  final GroupService groupService;
  final AuthService authService;

  const _NotificationsSection({
    required this.meeting,
    required this.groupService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GroupModel>(
      future: groupService.getGroup(meeting.grupoId).then((r) => r.data!),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final group = groupSnapshot.data!;
        final totalMiembros = group.miembrosIds.length;
        final visto = meeting.miembrosNotificados.length;
        final noVisto = totalMiembros - visto;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notificación Vista',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$visto de $totalMiembros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: visto == totalMiembros
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: visto / totalMiembros,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  color: visto == totalMiembros ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, String>>(
                  future: authService
                      .getUserNames(group.miembrosIds)
                      .then((r) => r.data ?? {}),
                  builder: (context, namesSnapshot) {
                    if (!namesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final nombres = namesSnapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (meeting.miembrosNotificados.isNotEmpty) ...[
                          const Text(
                            '✅ Han visto:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...meeting.miembrosNotificados.map((userId) {
                            return _buildMemberRow(
                              nombres[userId] ?? 'Usuario desconocido',
                              Icons.check_circle,
                              Colors.green,
                            );
                          }),
                        ],
                        if (noVisto > 0) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '❌ No han visto:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...group.miembrosIds
                              .where(
                                (id) =>
                                    !meeting.miembrosNotificados.contains(id),
                              )
                              .map((userId) {
                                return _buildMemberRow(
                                  nombres[userId] ?? 'Usuario desconocido',
                                  Icons.cancel,
                                  Colors.red,
                                );
                              }),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberRow(String name, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }
}

// ==================== ATTENDANCE SECTION ====================

class _AttendanceSection extends StatelessWidget {
  final MeetingModel meeting;
  final String? userId;
  final bool isPresident;
  final GroupService groupService;
  final AuthService authService;
  final MeetingService meetingService;
  final VoidCallback onAttendanceChanged;

  const _AttendanceSection({
    required this.meeting,
    required this.userId,
    required this.isPresident,
    required this.groupService,
    required this.authService,
    required this.meetingService,
    required this.onAttendanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final yaAsisti = userId != null && meeting.usuarioAsistio(userId!);

    return FutureBuilder<GroupModel>(
      future: groupService.getGroup(meeting.grupoId).then((r) => r.data!),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final group = groupSnapshot.data!;
        final totalMiembros = group.miembrosIds.length;
        final asistieron = meeting.asistentes.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Asistencia Presencial',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$asistieron de $totalMiembros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: asistieron > 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: asistieron / totalMiembros,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  color: Colors.green,
                ),
                const SizedBox(height: 16),

                // Botón de asistencia
                if (meeting.puedeMarcarAsistencia && userId != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: yaAsisti
                          ? 'Ya marcaste asistencia'
                          : 'Marcar mi asistencia',
                      icon: yaAsisti ? Icons.check_circle : Icons.check,
                      backgroundColor: yaAsisti ? Colors.grey : Colors.green,
                      onPressed: yaAsisti
                          ? null
                          : () => _handleMarkAttendance(context, userId!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (meeting.horaInicio == null &&
                    !meeting.finalizada) ...[
                  _buildInfoBox(
                    'La asistencia se podrá marcar cuando el presidente inicie la reunión',
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                ] else if (meeting.finalizada) ...[
                  _buildInfoBox(
                    'La reunión ha finalizado. Ya no se puede marcar asistencia',
                    Colors.grey,
                  ),
                  const SizedBox(height: 16),
                ],

                // Lista de asistentes
                if (meeting.asistentes.isNotEmpty)
                  FutureBuilder<Map<String, String>>(
                    future: authService
                        .getUserNames(meeting.asistentes)
                        .then((r) => r.data ?? {}),
                    builder: (context, namesSnapshot) {
                      if (!namesSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final nombres = namesSnapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Asistentes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...meeting.asistentes.map((userId) {
                            return ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                nombres[userId] ?? 'Usuario desconocido',
                              ),
                              trailing:
                                  isPresident && meeting.puedeMarcarAsistencia
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Quitar asistencia',
                                      onPressed: () => _handleRemoveAttendance(
                                        context,
                                        userId,
                                        nombres[userId] ?? 'Usuario',
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        ],
                      );
                    },
                  )
                else
                  Text(
                    meeting.horaInicio == null
                        ? 'La reunión aún no ha iniciado'
                        : 'Aún no hay asistentes registrados',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkAttendance(
    BuildContext context,
    String userId,
  ) async {
    final result = await meetingService.marcarAsistencia(meeting.id, userId);

    if (context.mounted) {
      if (result.isSuccess) {
        showSuccessSnackbar(context, '✅ Asistencia marcada');
        onAttendanceChanged();
      } else {
        showErrorSnackbar(context, result.errorMessage!);
      }
    }
  }

  Future<void> _handleRemoveAttendance(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Quitar asistencia',
      message: '¿Quitar asistencia de $userName?',
      confirmText: 'Quitar',
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final result = await meetingService.quitarAsistencia(meeting.id, userId);

      if (context.mounted) {
        if (result.isSuccess) {
          showSuccessSnackbar(context, '✅ Asistencia removida');
          onAttendanceChanged();
        } else {
          showErrorSnackbar(context, result.errorMessage!);
        }
      }
    }
  }
}

// ==================== TIMES SECTION ====================

class _TimesSection extends StatelessWidget {
  final MeetingModel meeting;
  final DateFormat timeFormat;

  const _TimesSection({required this.meeting, required this.timeFormat});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro de Tiempos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            if (meeting.horaInicio != null) ...[
              _buildDetailRow(
                Icons.play_arrow,
                'Hora de inicio',
                timeFormat.format(meeting.horaInicio!),
              ),
              const SizedBox(height: 12),
            ],
            if (meeting.horaFin != null) ...[
              _buildDetailRow(
                Icons.stop,
                'Hora de finalización',
                timeFormat.format(meeting.horaFin!),
              ),
              const SizedBox(height: 12),
            ],
            if (meeting.duracion != null) ...[
              _buildDetailRow(
                Icons.timer,
                'Duración',
                _formatDuration(meeting.duracion!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

// ==================== PRESIDENT ACTIONS ====================

class _PresidentActions extends StatelessWidget {
  final MeetingModel meeting;
  final bool isLoading;
  final MeetingService meetingService;
  final Function(bool) onLoadingChanged;

  const _PresidentActions({
    required this.meeting,
    required this.isLoading,
    required this.meetingService,
    required this.onLoadingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones de Presidente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Botón INICIAR
            if (meeting.horaInicio == null && meeting.puedeIniciar)
              PrimaryButton(
                label: 'Iniciar Reunión',
                icon: Icons.play_arrow,
                backgroundColor: Colors.green,
                isLoading: isLoading,
                onPressed: () => _handleStartMeeting(context),
              ),

            // Botón FINALIZAR
            if (meeting.horaInicio != null && meeting.horaFin == null) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Finalizar Reunión',
                icon: Icons.stop,
                backgroundColor: Colors.red,
                isLoading: isLoading,
                onPressed: () => _handleEndMeeting(context),
              ),
            ],

            // Botón CANCELAR
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Cancelar Reunión',
              icon: Icons.cancel,
              color: Colors.red,
              onPressed: isLoading ? null : () => _handleCancelMeeting(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartMeeting(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: '🎬 Iniciar Reunión',
      message:
          '¿Deseas iniciar esta reunión ahora?\n\n'
          'Se registrará la hora de inicio.',
    );

    if (confirm == true && context.mounted) {
      onLoadingChanged(true);
      final result = await meetingService.iniciarReunion(meeting.id);
      onLoadingChanged(false);

      if (context.mounted) {
        if (result.isSuccess) {
          showSuccessSnackbar(context, '✅ Reunión iniciada');
        } else {
          showErrorSnackbar(context, result.errorMessage!);
        }
      }
    }
  }

  Future<void> _handleEndMeeting(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: '🏁 Finalizar Reunión',
      message:
          '¿Deseas finalizar esta reunión?\n\n'
          'Asistentes: ${meeting.asistentes.length}\n'
          'Se registrará la hora de finalización.',
    );

    if (confirm == true && context.mounted) {
      onLoadingChanged(true);
      final result = await meetingService.finalizarReunion(meeting.id);
      onLoadingChanged(false);

      if (context.mounted) {
        if (result.isSuccess) {
          showSuccessSnackbar(context, '✅ Reunión finalizada');
        } else {
          showErrorSnackbar(context, result.errorMessage!);
        }
      }
    }
  }

  Future<void> _handleCancelMeeting(BuildContext context) async {
    final confirm = await showConfirmDialog(
      context,
      title: '❌ Cancelar Reunión',
      message:
          '¿Estás seguro de que deseas cancelar esta reunión?\n\n'
          'Los miembros serán notificados de la cancelación.',
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      onLoadingChanged(true);
      final result = await meetingService.cancelMeeting(meeting.id);
      onLoadingChanged(false);

      if (context.mounted) {
        if (result.isSuccess) {
          showSuccessSnackbar(context, '✅ Reunión cancelada');
          Navigator.pop(context);
        } else {
          showErrorSnackbar(context, result.errorMessage!);
        }
      }
    }
  }
}
