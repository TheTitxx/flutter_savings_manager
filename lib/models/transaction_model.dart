import 'package:flutter/material.dart';
import '../core/models/base_model.dart';

// ==================== ENUM ====================

/// Tipos de transacciones
enum TipoTransaccion {
  ahorro,
  retiro,
  prestamo,
  pagoPrestamo,
  interes,
  utilidad;

  /// ✅ Obtener nombre legible
  String get nombre {
    switch (this) {
      case TipoTransaccion.ahorro:
        return 'Ahorro';
      case TipoTransaccion.retiro:
        return 'Retiro';
      case TipoTransaccion.prestamo:
        return 'Préstamo';
      case TipoTransaccion.pagoPrestamo:
        return 'Pago Préstamo';
      case TipoTransaccion.interes:
        return 'Interés';
      case TipoTransaccion.utilidad:
        return 'Utilidad';
    }
  }

  /// ✅ Obtener color asociado
  Color get color {
    switch (this) {
      case TipoTransaccion.ahorro:
        return Colors.green;
      case TipoTransaccion.retiro:
        return Colors.red;
      case TipoTransaccion.prestamo:
        return Colors.orange;
      case TipoTransaccion.pagoPrestamo:
        return Colors.blue;
      case TipoTransaccion.interes:
        return Colors.purple;
      case TipoTransaccion.utilidad:
        return Colors.teal;
    }
  }

  /// ✅ Obtener icono asociado
  IconData get icono {
    switch (this) {
      case TipoTransaccion.ahorro:
        return Icons.savings;
      case TipoTransaccion.retiro:
        return Icons.arrow_circle_down;
      case TipoTransaccion.prestamo:
        return Icons.credit_card;
      case TipoTransaccion.pagoPrestamo:
        return Icons.payment;
      case TipoTransaccion.interes:
        return Icons.trending_up;
      case TipoTransaccion.utilidad:
        return Icons.diamond;
    }
  }

  /// ✅ Determinar si es ingreso
  bool get esIngreso {
    return this == TipoTransaccion.ahorro ||
        this == TipoTransaccion.pagoPrestamo ||
        this == TipoTransaccion.interes ||
        this == TipoTransaccion.utilidad;
  }
}

// ==================== MODEL ====================

/// ✅ TRANSACTION MODEL OPTIMIZADO
class TransactionModel extends BaseModel {
  final String id;
  final String grupoId;
  final String userId;
  final TipoTransaccion tipo;
  final double monto;
  final DateTime fecha;
  final String descripcion;
  final String? referencia;

  TransactionModel({
    required this.id,
    required this.grupoId,
    required this.userId,
    required this.tipo,
    required this.monto,
    required this.fecha,
    required this.descripcion,
    this.referencia,
  });

  // ==================== SERIALIZACIÓN ====================

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grupoId': grupoId,
      'userId': userId,
      'tipo': tipo.name, // ✅ Usar .name en vez de split
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'referencia': referencia,
    };
  }

  /// ✅ FACTORY simplificado
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map.getOrDefault('id', ''),
      grupoId: map.getOrDefault('grupoId', ''),
      userId: map.getOrDefault('userId', ''),
      tipo: _parseTipo(map['tipo']),
      monto: BaseModel.parseDouble(map['monto']),
      fecha: BaseModel.parseDate(map['fecha']),
      descripcion: map.getOrDefault('descripcion', ''),
      referencia: map['referencia'],
    );
  }

  /// ✅ Parser de tipo seguro
  static TipoTransaccion _parseTipo(dynamic value) {
    if (value == null) return TipoTransaccion.ahorro;

    final stringValue = value.toString();

    try {
      return TipoTransaccion.values.firstWhere(
        (e) => e.name == stringValue,
        orElse: () => TipoTransaccion.ahorro,
      );
    } catch (e) {
      return TipoTransaccion.ahorro;
    }
  }

  // ==================== GETTERS ÚTILES ====================

  /// Obtener color según el tipo (delegado al enum)
  Color get color => tipo.color;

  /// Obtener icono según el tipo (delegado al enum)
  IconData get icono => tipo.icono;

  /// Obtener nombre legible del tipo (delegado al enum)
  String get tipoNombre => tipo.nombre;

  /// Determinar si es ingreso (delegado al enum)
  bool esIngreso() => tipo.esIngreso;

  /// Obtener color en formato hex (legacy - mantener compatibilidad)
  @Deprecated('Usar tipo.color directamente')
  String getColorHex() {
    final color = tipo.color;
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Obtener icono como string (legacy - mantener compatibilidad)
  @Deprecated('Usar tipo.icono directamente')
  String getIcono() {
    switch (tipo) {
      case TipoTransaccion.ahorro:
        return '💰';
      case TipoTransaccion.retiro:
        return '💸';
      case TipoTransaccion.prestamo:
        return '🏦';
      case TipoTransaccion.pagoPrestamo:
        return '💳';
      case TipoTransaccion.interes:
        return '📈';
      case TipoTransaccion.utilidad:
        return '💎';
    }
  }

  /// Obtener nombre del tipo (legacy - mantener compatibilidad)
  @Deprecated('Usar tipo.nombre directamente')
  String getTipoNombre() => tipoNombre;

  /// Es transacción reciente (menos de 24 horas)
  bool get esReciente {
    return DateTime.now().difference(fecha).inHours < 24;
  }

  /// Obtener monto formateado
  String get montoFormateado {
    final signo = esIngreso() ? '+' : '-';
    return '$signo\$${monto.toStringAsFixed(2)}';
  }

  // ==================== VALIDACIONES ====================

  /// Valida si tiene referencia
  bool get tieneReferencia => referencia != null && referencia!.isNotEmpty;

  /// Valida si el monto es positivo
  bool get montoValido => monto > 0;

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, tipo: ${tipo.nombre}, monto: $monto)';
  }
}
