import '../core/models/base_model.dart';

/// ✅ LOAN PAYMENT MODEL OPTIMIZADO
class LoanPaymentModel extends BaseModel {
  final String id;
  final String loanRequestId;
  final String grupoId;
  final String userId;
  final double montoPagado;
  final DateTime fechaPago;
  final String descripcion;
  final int numeroCuota;

  LoanPaymentModel({
    required this.id,
    required this.loanRequestId,
    required this.grupoId,
    required this.userId,
    required this.montoPagado,
    required this.fechaPago,
    required this.descripcion,
    required this.numeroCuota,
  });

  // ==================== SERIALIZACIÓN ====================

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loanRequestId': loanRequestId,
      'grupoId': grupoId,
      'userId': userId,
      'montoPagado': montoPagado,
      'fechaPago': fechaPago.toIso8601String(),
      'descripcion': descripcion,
      'numeroCuota': numeroCuota,
    };
  }

  /// ✅ FACTORY simplificado con BaseModel
  factory LoanPaymentModel.fromMap(Map<String, dynamic> map) {
    return LoanPaymentModel(
      id: map.getOrDefault('id', ''),
      loanRequestId: map.getOrDefault('loanRequestId', ''),
      grupoId: map.getOrDefault('grupoId', ''),
      userId: map.getOrDefault('userId', ''),
      montoPagado: BaseModel.parseDouble(map['montoPagado']),
      fechaPago: BaseModel.parseDate(map['fechaPago']),
      descripcion: map.getOrDefault('descripcion', ''),
      numeroCuota: BaseModel.parseInt(map['numeroCuota']),
    );
  }

  // ==================== GETTERS ÚTILES ====================

  /// Es pago reciente (menos de 7 días)
  bool get esReciente {
    return DateTime.now().difference(fechaPago).inDays < 7;
  }

  /// Monto formateado
  String get montoFormateado => '\$${montoPagado.toStringAsFixed(2)}';

  /// Descripción de la cuota
  String get descripcionCuota => 'Cuota #$numeroCuota';

  // ==================== VALIDACIONES ====================

  /// Valida si el monto es positivo
  bool get montoValido => montoPagado > 0;

  /// Valida si tiene descripción
  bool get tieneDescripcion => descripcion.isNotEmpty;

  // ==================== IGUALDAD ====================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoanPaymentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LoanPaymentModel(id: $id, cuota: $numeroCuota, monto: $montoPagado)';
  }
}
