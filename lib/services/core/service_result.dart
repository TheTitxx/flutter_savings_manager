/// Resultado genérico para operaciones de servicio
///
/// Reemplaza el uso de bool/null con un tipo más expresivo
/// que incluye datos, errores y mensajes descriptivos.
///
/// Ejemplo de uso:
/// ```dart
/// final result = await authService.signIn(email, password);
/// if (result.isSuccess) {
///   print('Usuario: ${result.data!.nombre}');
/// } else {
///   print('Error: ${result.errorMessage}');
/// }
/// ```
class ServiceResult<T> {
  final T? data;
  final String? errorMessage;
  final Exception? exception;
  final bool isSuccess;

  const ServiceResult._({
    this.data,
    this.errorMessage,
    this.exception,
    required this.isSuccess,
  });

  /// Crea un resultado exitoso con datos
  factory ServiceResult.success(T data) {
    return ServiceResult._(data: data, isSuccess: true);
  }

  /// Crea un resultado exitoso sin datos (para operaciones void)
  factory ServiceResult.successVoid() {
    return ServiceResult._(isSuccess: true);
  }

  /// Crea un resultado fallido con mensaje de error
  factory ServiceResult.failure(String message, [Exception? exception]) {
    return ServiceResult._(
      errorMessage: message,
      exception: exception,
      isSuccess: false,
    );
  }

  /// Crea un resultado fallido desde una excepción
  factory ServiceResult.fromException(Exception exception) {
    return ServiceResult._(
      errorMessage: exception.toString(),
      exception: exception,
      isSuccess: false,
    );
  }

  /// Indica si la operación falló
  bool get isFailure => !isSuccess;

  /// Obtiene el dato o lanza una excepción si falló
  T get dataOrThrow {
    if (isFailure) {
      throw exception ?? Exception(errorMessage ?? 'Operación fallida');
    }
    return data!;
  }

  /// Transforma el dato si existe
  ServiceResult<R> map<R>(R Function(T data) transform) {
    if (isFailure) {
      return ServiceResult.failure(errorMessage!, exception);
    }
    try {
      return ServiceResult.success(transform(data as T));
    } catch (e) {
      return ServiceResult.failure(
        'Error al transformar datos: $e',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ServiceResult.success(data: $data)';
    } else {
      return 'ServiceResult.failure(error: $errorMessage)';
    }
  }
}

/// Extensión para convertir Future  en ServiceResult
extension FutureServiceResultExtension<T> on Future<T?> {
  Future<ServiceResult<T>> toServiceResult(String errorMessage) async {
    try {
      final data = await this;
      if (data != null) {
        return ServiceResult.success(data);
      } else {
        return ServiceResult.failure(errorMessage);
      }
    } on Exception catch (e) {
      return ServiceResult.fromException(e);
    } catch (e) {
      return ServiceResult.failure(e.toString());
    }
  }
}
