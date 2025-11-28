import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/meeting_service.dart';

// Models
import '../../models/meeting_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/custom_cards.dart';

// Screens
import 'create_meeting_screen.dart';
import 'meeting_detail_screen.dart';

/// ✅ MEETINGS SCREEN - OPTIMIZADO
///
/// Cambios:
/// - ✅ Usa MeetingService con Service Locator
/// - ✅ Marca reuniones como vistas automáticamente
/// - ✅ Mejor organización de reuniones (próximas/pasadas)
/// - ✅ Usa widgets reutilizables (MeetingCard)
class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  // 🎯 Service Locator
  final MeetingService _meetingService = getIt<MeetingService>();

  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.currentUser?.uid ?? '';

    // ✅ Marcar todas las reuniones como vistas al abrir
    _markAllAsViewed();
  }

  /// Marca todas las reuniones como vistas
  Future<void> _markAllAsViewed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.selectedGroup == null ||
        authProvider.currentUser == null) {
      return;
    }

    try {
      // Obtener snapshot de reuniones
      final snapshot = await _meetingService.getGroupMeetingsSnapshot(
        authProvider.selectedGroup!.id,
      );

      // Marcar cada reunión no vista
      for (var doc in snapshot.docs) {
        try {
          final meeting = MeetingModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );

          if (!meeting.usuarioNotificado(_currentUserId)) {
            await _meetingService.markMeetingAsViewed(
              meeting.id,
              _currentUserId,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error al marcar reunión como vista: $e');
        }
      }

      debugPrint('✅ Reuniones marcadas como vistas');
    } catch (e) {
      debugPrint('⚠️ Error en _markAllAsViewed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final group = authProvider.selectedGroup;
    final user = authProvider.currentUser;
    final isPresident = authProvider.isPresident;

    if (group == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reuniones')),
        body: const EmptyStateWidget(
          icon: Icons.event_busy,
          title: 'No hay grupo seleccionado',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuniones del Grupo'),
        actions: [
          if (isPresident)
            IconButton(
              icon: const Icon(Icons.add_circle),
              tooltip: 'Programar Reunión',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateMeetingScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<MeetingModel>>(
        stream: _meetingService.getGroupMeetings(group.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Cargando reuniones...');
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: 'Error al cargar reuniones',
              onRetry: () => setState(() {}),
            );
          }

          final allMeetings = snapshot.data ?? [];

          if (allMeetings.isEmpty) {
            return _buildEmptyState(isPresident);
          }

          // Separar reuniones próximas y pasadas
          final now = DateTime.now();
          final proximas = allMeetings
              .where((m) => m.fechaHora.isAfter(now) && m.activa)
              .toList();
          final pasadas = allMeetings
              .where((m) => m.fechaHora.isBefore(now) || !m.activa)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Reuniones Próximas
                if (proximas.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Próximas Reuniones',
                    proximas.length,
                    Icons.upcoming,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  ...proximas.map(
                    (meeting) => MeetingCard(
                      titulo: meeting.titulo,
                      fechaHora: meeting.fechaHora,
                      creadoPor: meeting.creadoPorNombre,
                      descripcion: meeting.descripcion,
                      esNueva: meeting.esNueva,
                      activa: meeting.activa,
                      onTap: () => _navigateToDetail(meeting),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Reuniones Pasadas
                if (pasadas.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Reuniones Anteriores',
                    pasadas.length,
                    Icons.history,
                    Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  ...pasadas.map(
                    (meeting) => MeetingCard(
                      titulo: meeting.titulo,
                      fechaHora: meeting.fechaHora,
                      creadoPor: meeting.creadoPorNombre,
                      descripcion: meeting.descripcion,
                      esNueva: false,
                      activa: meeting.activa,
                      onTap: () => _navigateToDetail(meeting),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: isPresident
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateMeetingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Reunión'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  /// Construye el header de cada sección
  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el estado vacío
  Widget _buildEmptyState(bool isPresident) {
    return EmptyStateWidget(
      icon: Icons.event_busy,
      title: 'No hay reuniones programadas',
      subtitle: isPresident
          ? 'Programa la primera reunión del grupo'
          : 'El presidente aún no ha programado reuniones',
      action: isPresident
          ? ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateMeetingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Programar Primera Reunión'),
            )
          : null,
    );
  }

  /// Navega al detalle de la reunión
  void _navigateToDetail(MeetingModel meeting) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MeetingDetailScreen(meeting: meeting)),
    );
  }
}
