import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Core
import '../../providers/auth_provider.dart';
import '../../core/di/service_locator.dart';

// Services
import '../../services/meeting_service.dart';

// Models
import '../../models/meeting_model.dart';

// Widgets
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/custom_buttons.dart';

/// ✅ CREATE MEETING SCREEN - OPTIMIZADO
///
/// Cambios:
/// - ✅ Usa MeetingService con Service Locator
/// - ✅ Validaciones mejoradas de fecha/hora
/// - ✅ Mejor UX con feedback visual
/// - ✅ Usa widgets reutilizables
class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  // 🎯 Service Locator
  final MeetingService _meetingService = getIt<MeetingService>();

  // Form
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Estado
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Valida que la fecha/hora sea válida (mínimo 30 min después)
  bool _isValidDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final minDateTime = now.add(const Duration(minutes: 30));
    return dateTime.isAfter(minDateTime);
  }

  /// Selecciona la fecha de la reunión
  Future<void> _selectDate() async {
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Seleccionar fecha de reunión',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validar si es hoy
      if (picked.year == now.year &&
          picked.month == now.month &&
          picked.day == now.day) {
        // Es hoy - validar hora si ya está seleccionada
        if (_selectedTime != null) {
          final selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );

          if (!_isValidDateTime(selectedDateTime)) {
            if (mounted) {
              showErrorSnackbar(
                context,
                '⚠️ La reunión debe ser mínimo 30 minutos después',
              );
            }
            return;
          }
        }
      }

      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Selecciona la hora de la reunión
  Future<void> _selectTime() async {
    final now = DateTime.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Seleccionar hora de reunión',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validar si la fecha es hoy
      if (_selectedDate != null &&
          _selectedDate!.year == now.year &&
          _selectedDate!.month == now.month &&
          _selectedDate!.day == now.day) {
        final selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );

        if (!_isValidDateTime(selectedDateTime)) {
          if (mounted) {
            showErrorSnackbar(
              context,
              '⚠️ La reunión debe ser mínimo 30 minutos después',
            );
          }
          return;
        }
      }

      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// Crea la reunión
  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación 1: Fecha seleccionada
    if (_selectedDate == null) {
      showErrorSnackbar(context, '❌ Por favor selecciona una fecha');
      return;
    }

    // Validación 2: Hora seleccionada
    if (_selectedTime == null) {
      showErrorSnackbar(context, '❌ Por favor selecciona una hora');
      return;
    }

    // Validación 3: Fecha + Hora válidas
    final fechaHora = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (!_isValidDateTime(fechaHora)) {
      showErrorSnackbar(
        context,
        '❌ La reunión debe ser mínimo 30 minutos después',
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null ||
        authProvider.selectedGroup == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorSnackbar(context, '❌ Error: Usuario o grupo no encontrado');
      }
      return;
    }

    try {
      // Crear referencia con ID único
      final meetingRef = _meetingService.createMeetingRef();

      final meeting = MeetingModel(
        id: meetingRef.id,
        grupoId: authProvider.selectedGroup!.id,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        fechaHora: fechaHora,
        creadoPorId: authProvider.currentUser!.uid,
        creadoPorNombre: authProvider.currentUser!.nombre,
        fechaCreacion: DateTime.now(),
      );

      // Guardar usando el servicio
      final result = await _meetingService.createMeeting(meeting);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result.isSuccess) {
        await _showSuccessDialog(meeting);
      } else {
        showErrorSnackbar(
          context,
          result.errorMessage ?? '❌ Error al programar reunión',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorSnackbar(context, '❌ Error: $e');
      }
      debugPrint('❌ Error al crear reunión: $e');
    }
  }

  /// Muestra diálogo de éxito
  Future<void> _showSuccessDialog(MeetingModel meeting) async {
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
            const Expanded(child: Text('✅ ¡Reunión Programada!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La reunión "${meeting.titulo}" ha sido programada exitosamente.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.event, size: 40, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'EEEE, dd \'de\' MMMM',
                    ).format(meeting.fechaHora),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(meeting.fechaHora),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos los miembros del grupo han sido notificados.',
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
              Navigator.of(context).pop(); // Volver a reuniones
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programar Reunión'),
        backgroundColor: Colors.blue,
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.event_available,
                    size: 60,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Título
              const Text(
                'Nueva Reunión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Programa una reunión con los miembros del grupo',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Campo Título
              TextFormField(
                controller: _tituloController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Título de la reunión *',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'Ej: Reunión mensual de revisión',
                  helperText: 'Nombre descriptivo de la reunión',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  if (value.length < 5) {
                    return 'El título debe tener al menos 5 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Selector de Fecha
              InkWell(
                onTap: _isLoading ? null : _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDate == null
                          ? Colors.grey[300]!
                          : Colors.blue,
                      width: _selectedDate == null ? 1 : 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _selectedDate == null
                            ? Colors.grey[600]
                            : Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de la reunión *',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate == null
                                  ? 'Seleccionar fecha'
                                  : dateFormat.format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _selectedDate == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: _selectedDate == null
                                    ? Colors.grey[600]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de Hora
              InkWell(
                onTap: _isLoading ? null : _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTime == null
                          ? Colors.grey[300]!
                          : Colors.blue,
                      width: _selectedTime == null ? 1 : 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: _selectedTime == null
                            ? Colors.grey[600]
                            : Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hora de la reunión *',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTime == null
                                  ? 'Seleccionar hora'
                                  : timeFormat.format(
                                      DateTime(
                                        2024,
                                        1,
                                        1,
                                        _selectedTime!.hour,
                                        _selectedTime!.minute,
                                      ),
                                    ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _selectedTime == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: _selectedTime == null
                                    ? Colors.grey[600]
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Campo Descripción (Opcional)
              TextFormField(
                controller: _descripcionController,
                enabled: !_isLoading,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Describe el tema o propósito de la reunión',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Importante:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('✅ Mínimo 30 minutos después de ahora'),
                    _buildInfoItem('✅ Todos los miembros serán notificados'),
                    _buildInfoItem(
                      '✅ La reunión aparecerá en el apartado de reuniones',
                    ),
                    _buildInfoItem('✅ Puedes cancelarla en cualquier momento'),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Botón Programar
              PrimaryButton(
                label: 'Programar Reunión',
                icon: Icons.event_available,
                isLoading: _isLoading,
                onPressed: _createMeeting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
