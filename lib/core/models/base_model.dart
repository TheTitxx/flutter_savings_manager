import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎯 CLASE BASE para todos los modelos
///
/// Ventajas:
/// ✅ Centraliza conversión de fechas
/// ✅ Evita código duplicado
/// ✅ Manejo consistente de errores
/// ✅ Facilita testing
abstract class BaseModel {
  /// Convierte el modelo a Map para Firebase
  Map<String, dynamic> toMap();

  // ==================== HELPERS ESTÁTICOS ====================

  /// Convierte cualquier tipo de fecha a DateTime local
  ///
  /// Soporta: Timestamp, String ISO, DateTime
  static DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate().toLocal();
    } else if (value is String) {
      return DateTime.parse(value).toLocal();
    } else if (value is DateTime) {
      return value.toLocal();
    }

    return DateTime.now();
  }

  /// Convierte DateTime a formato Firebase
  static dynamic dateToFirebase(DateTime date) {
    return Timestamp.fromDate(date.toUtc());
  }

  /// Parsea double de manera segura
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  /// Parsea int de manera segura
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  /// Parsea lista de strings de manera segura
  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Parsea mapa de manera segura
  static Map<String, dynamic> parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// Valida que un campo requerido exista
  static T validateRequired<T>(dynamic value, String fieldName) {
    if (value == null) {
      throw ArgumentError('Campo requerido "$fieldName" no puede ser null');
    }
    return value as T;
  }
}

/// 🛡️ EXTENSIÓN para validaciones comunes
extension ModelValidation on Map<String, dynamic> {
  /// Obtiene un valor o lanza excepción si no existe
  T getRequired<T>(String key) {
    if (!containsKey(key)) {
      throw ArgumentError('Campo requerido "$key" no encontrado');
    }
    return this[key] as T;
  }

  /// Obtiene un valor o retorna default
  T getOrDefault<T>(String key, T defaultValue) {
    return (this[key] ?? defaultValue) as T;
  }
}
