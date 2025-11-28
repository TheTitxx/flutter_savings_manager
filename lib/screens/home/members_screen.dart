import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/group_service.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';

// Models
import '../../models/member_info_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/custom_cards.dart';

/// ✅ MEMBERS SCREEN - OPTIMIZADO
///
/// Cambios:
/// - ✅ Usa GroupService con Service Locator
/// - ✅ Usa TransactionService para estadísticas
/// - ✅ Usa widgets reutilizables
/// - ✅ Mejor organización del código
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  // 🎯 Service Locator
  final GroupService _groupService = getIt<GroupService>();
  final TransactionService _transactionService = getIt<TransactionService>();
  final AuthService _authService = getIt<AuthService>();

  // Estado
  List<MemberInfo> _members = [];
  bool _isLoading = true;
  String _sortBy = 'ahorros';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.selectedGroup == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Obtener grupo actualizado
      final groupResult = await _groupService.getGroup(
        authProvider.selectedGroup!.id,
      );

      if (groupResult.isFailure || groupResult.data == null) {
        setState(() {
          _members = [];
          _isLoading = false;
        });
        return;
      }

      final group = groupResult.data!;
      final List<MemberInfo> membersList = [];

      // Cargar información de cada miembro
      for (final memberId in group.miembrosIds) {
        try {
          // Obtener datos del usuario
          final userResult = await _authService.getUserById(memberId);
          if (userResult.isFailure) continue;

          final user = userResult.data!;

          // Obtener estadísticas de transacciones
          final statsResult = await _transactionService.getUserTransactionStats(
            group.id,
            memberId,
          );

          final stats = statsResult.isSuccess
              ? statsResult.data!
              : <String, dynamic>{
                  'ahorros': 0.0,
                  'retiros': 0.0,
                  'saldoNeto': 0.0,
                  'total': 0,
                };

          // Crear MemberInfo
          final memberInfo = MemberInfo(
            user: user,
            totalAhorros: stats['ahorros'] ?? 0.0,
            totalRetiros: stats['retiros'] ?? 0.0,
            prestamosActivos: 0.0, // Implementar cálculo de préstamos activos
            numeroTransacciones: stats['total'] ?? 0,
            fechaIngreso: user.fechaRegistro,
            esPresidente: group.presidenteId == memberId,
          );

          membersList.add(memberInfo);
        } catch (e) {
          debugPrint('⚠️ Error al cargar miembro $memberId: $e');
        }
      }

      setState(() {
        _members = membersList;
        _isLoading = false;
      });

      // Aplicar ordenamiento inicial
      _sortMembers(_sortBy);
    } catch (e) {
      debugPrint('❌ Error al cargar miembros: $e');
      setState(() {
        _members = [];
        _isLoading = false;
      });
    }
  }

  void _sortMembers(String sortType) {
    setState(() {
      _sortBy = sortType;
      switch (sortType) {
        case 'ahorros':
          _members.sort((a, b) => b.totalAhorros.compareTo(a.totalAhorros));
          break;
        case 'nombre':
          _members.sort((a, b) => a.user.nombre.compareTo(b.user.nombre));
          break;
        case 'fecha':
          _members.sort((a, b) => a.fechaIngreso.compareTo(b.fechaIngreso));
          break;
        case 'transacciones':
          _members.sort(
            (a, b) => b.numeroTransacciones.compareTo(a.numeroTransacciones),
          );
          break;
      }
    });
  }

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
        appBar: AppBar(title: const Text('Miembros')),
        body: const EmptyStateWidget(
          icon: Icons.group_off,
          title: 'No hay grupo seleccionado',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Miembros de ${group.nombre}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _sortMembers,
            itemBuilder: (context) => [
              _buildSortMenuItem(
                'ahorros',
                'Por Ahorros',
                Icons.account_balance_wallet,
              ),
              _buildSortMenuItem('nombre', 'Por Nombre', Icons.sort_by_alpha),
              _buildSortMenuItem(
                'fecha',
                'Por Antigüedad',
                Icons.calendar_today,
              ),
              _buildSortMenuItem(
                'transacciones',
                'Por Actividad',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: _isLoading
            ? const LoadingWidget(message: 'Cargando miembros...')
            : _members.isEmpty
            ? _buildEmptyState(authProvider.isPresident, group.codigoInvitacion)
            : _buildMembersList(
                group,
                currencyFormat,
                authProvider.isPresident,
              ),
      ),
    );
  }

  // ==================== UI BUILDERS ====================

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

  Widget _buildEmptyState(bool isPresident, String codigoInvitacion) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'No hay miembros en este grupo',
      subtitle: isPresident
          ? 'Comparte el código de invitación para agregar miembros'
          : null,
      action: isPresident
          ? ElevatedButton.icon(
              onPressed: () => _showInvitationCode(context, codigoInvitacion),
              icon: const Icon(Icons.share),
              label: const Text('Compartir Código'),
            )
          : null,
    );
  }

  Widget _buildMembersList(
    dynamic group,
    NumberFormat currencyFormat,
    bool isPresident,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Estadísticas del grupo
        _buildGroupStats(group, currencyFormat),
        const SizedBox(height: 24),

        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${_members.length} miembros',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isPresident)
              TextButton.icon(
                onPressed: () =>
                    _showInvitationCode(context, group.codigoInvitacion),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Código'),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de miembros
        ..._members.map((member) {
          return MemberCard(
            nombre: member.user.nombre,
            email: member.user.email,
            totalAhorros: member.totalAhorros,
            saldoNeto: member.saldoNeto,
            numeroTransacciones: member.numeroTransacciones,
            esPresidente: member.esPresidente,
            porcentajeAporte: member.calcularPorcentajeAporte(
              group.totalAhorros,
            ),
            onTap: () => _showMemberDetails(member, currencyFormat),
          );
        }),
      ],
    );
  }

  Widget _buildGroupStats(dynamic group, NumberFormat currencyFormat) {
    // Calcular promedio por miembro
    final promedioAhorros = _members.isNotEmpty
        ? group.totalAhorros / _members.length
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Resumen del Grupo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Ahorros',
                  currencyFormat.format(group.totalAhorros),
                  Icons.savings,
                ),
                _buildStatItem(
                  'Promedio',
                  currencyFormat.format(promedioAhorros),
                  Icons.show_chart,
                ),
                _buildStatItem('Miembros', '${_members.length}', Icons.people),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ==================== DIALOGS ====================

  void _showMemberDetails(MemberInfo member, NumberFormat currencyFormat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar y nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: member.esPresidente
                      ? Colors.orange
                      : Colors.blue,
                  child: Text(
                    member.user.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
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
                        member.user.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        member.user.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (member.esPresidente)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRESIDENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Detalles
            _buildDetailRow('Teléfono', member.user.telefono, Icons.phone),
            _buildDetailRow(
              'Miembro desde',
              DateFormat('dd/MM/yyyy').format(member.fechaIngreso),
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'Total Ahorros',
              currencyFormat.format(member.totalAhorros),
              Icons.savings,
            ),
            _buildDetailRow(
              'Saldo Neto',
              currencyFormat.format(member.saldoNeto),
              Icons.account_balance,
            ),
            _buildDetailRow(
              'Transacciones',
              '${member.numeroTransacciones}',
              Icons.receipt_long,
            ),
            _buildDetailRow(
              'Nivel de Participación',
              member.nivelParticipacionTexto,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showInvitationCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código de Invitación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_add, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Comparte este código con nuevos miembros:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
