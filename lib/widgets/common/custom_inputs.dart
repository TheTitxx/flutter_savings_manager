import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📝 INPUTS PERSONALIZADOS REUTILIZABLES
///
/// Ventajas:
/// ✅ Validaciones centralizadas
/// ✅ Estilos consistentes
/// ✅ Reducción de código duplicado

// ==================== CURRENCY INPUT ====================

/// Campo de entrada para montos monetarios
class CurrencyInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final String? Function(String?)? validator;
  final double? maxAmount;

  const CurrencyInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.validator,
    this.maxAmount,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? '0.00',
        prefixText: '\$ ',
        prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa un monto';
            }

            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Monto inválido';
            }

            if (maxAmount != null && amount > maxAmount!) {
              return 'Máximo: \$${maxAmount!.toStringAsFixed(2)}';
            }

            return null;
          },
    );
  }
}

// ==================== INTEGER INPUT ====================

/// Campo de entrada para números enteros
class IntegerInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final int? min;
  final int? max;
  final IconData? icon;

  const IntegerInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.min,
    this.max,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo requerido';
        }

        final number = int.tryParse(value);
        if (number == null) {
          return 'Número inválido';
        }

        if (min != null && number < min!) {
          return 'Mínimo: $min';
        }

        if (max != null && number > max!) {
          return 'Máximo: $max';
        }

        return null;
      },
    );
  }
}

// ==================== PERCENTAGE INPUT ====================

/// Campo de entrada para porcentajes
class PercentageInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final double min;
  final double max;

  const PercentageInput({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.min = 0.0,
    this.max = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: '5.0',
        suffixText: '%',
        prefixIcon: const Icon(Icons.percent, color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa un porcentaje';
        }

        final percentage = double.tryParse(value);
        if (percentage == null) {
          return 'Porcentaje inválido';
        }

        if (percentage < min || percentage > max) {
          return 'Debe estar entre $min% y $max%';
        }

        return null;
      },
    );
  }
}

// ==================== DESCRIPTION INPUT ====================

/// Campo de entrada para descripciones largas
class DescriptionInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final int minLength;

  const DescriptionInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.maxLines = 3,
    this.maxLength,
    this.minLength = 5,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.description),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo requerido';
        }

        if (value.length < minLength) {
          return 'Mínimo $minLength caracteres';
        }

        return null;
      },
    );
  }
}

// ==================== DATE PICKER INPUT ====================

/// Campo de selección de fecha
class DatePickerInput extends StatelessWidget {
  final DateTime? selectedDate;
  final String label;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;

  const DatePickerInput({
    super.key,
    this.selectedDate,
    required this.label,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedDate == null ? Colors.grey[300]! : Colors.blue,
            width: selectedDate == null ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: selectedDate == null ? Colors.grey[600] : Colors.blue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate == null
                        ? 'Seleccionar fecha'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedDate == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: selectedDate == null
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2100),
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}

// ==================== TIME PICKER INPUT ====================

/// Campo de selección de hora
class TimePickerInput extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final String label;
  final bool enabled;
  final Function(TimeOfDay) onTimeSelected;

  const TimePickerInput({
    super.key,
    this.selectedTime,
    required this.label,
    this.enabled = true,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _selectTime(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedTime == null ? Colors.grey[300]! : Colors.blue,
            width: selectedTime == null ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: selectedTime == null ? Colors.grey[600] : Colors.blue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedTime == null
                        ? 'Seleccionar hora'
                        : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedTime == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: selectedTime == null
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }
}

// ==================== SEARCH INPUT ====================

/// Campo de búsqueda con botón de limpiar
class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final VoidCallback? onClear;

  const SearchInput({
    super.key,
    required this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ==================== PASSWORD INPUT ====================

/// Campo de contraseña con toggle de visibilidad
class PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int minLength;

  const PasswordInput({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.minLength = 6,
  });

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo requerido';
        }

        if (value.length < widget.minLength) {
          return 'Mínimo ${widget.minLength} caracteres';
        }

        return null;
      },
    );
  }
}
