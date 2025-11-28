/// Nombres de colecciones de Firebase Firestore centralizados
///
/// Evita strings mágicos dispersos por el código.
/// Si cambia el nombre de una colección, solo se modifica aquí.
class FirebaseCollections {
  // Prevenir instanciación
  FirebaseCollections._();

  // Colecciones principales
  static const String users = 'users';
  static const String groups = 'groups';
  static const String transactions = 'transactions';
  static const String loanRequests = 'loan_requests';
  static const String loanPayments = 'loan_payments';
  static const String meetings = 'meetings';
  static const String notifications = 'notifications';
}

/// Nombres de campos comunes en documentos
class FirebaseFields {
  FirebaseFields._();

  // Campos comunes
  static const String id = 'id';
  static const String grupoId = 'grupoId';
  static const String userId = 'userId';
  static const String fecha = 'fecha';
  static const String estado = 'estado';
  static const String activa = 'activa';

  // Campos de grupos
  static const String codigoInvitacion = 'codigoInvitacion';
  static const String miembrosIds = 'miembrosIds';
  static const String totalAhorros = 'totalAhorros';
  static const String totalPrestamos = 'totalPrestamos';

  // Campos de transacciones
  static const String tipo = 'tipo';
  static const String monto = 'monto';

  // Campos de préstamos
  static const String solicitanteId = 'solicitanteId';
  static const String loanRequestId = 'loanRequestId';
  static const String montoPagado = 'montoPagado';
  static const String votos = 'votos';

  // Campos de reuniones
  static const String fechaHora = 'fechaHora';
  static const String miembrosNotificados = 'miembrosNotificados';
  static const String asistentes = 'asistentes';
  static const String horaInicio = 'horaInicio';
  static const String horaFin = 'horaFin';
  static const String finalizada = 'finalizada';
}

/// Mensajes de error estandarizados
class ErrorMessages {
  ErrorMessages._();

  // Errores de autenticación
  static const String authNoUser = 'No hay usuario autenticado';
  static const String authInvalidCredentials = 'Credenciales incorrectas';
  static const String authRegistrationFailed = 'Error al registrar usuario';
  static const String authSignInFailed = 'Error al iniciar sesión';

  // Errores de grupos
  static const String groupNotFound = 'Grupo no encontrado';
  static const String groupInvalidCode = 'Código de invitación inválido';
  static const String groupCreateFailed = 'Error al crear grupo';
  static const String groupJoinFailed = 'Error al unirse al grupo';

  // Errores de transacciones
  static const String transactionCreateFailed = 'Error al crear transacción';
  static const String transactionInsufficientFunds = 'Fondos insuficientes';

  // Errores de préstamos
  static const String loanNotFound = 'Préstamo no encontrado';
  static const String loanNotActive = 'El préstamo no está activo';
  static const String loanUnauthorized = 'No autorizado para este préstamo';
  static const String loanPaymentFailed = 'Error al registrar pago';
  static const String loanVoteFailed = 'Error al registrar voto';

  // Errores de reuniones
  static const String meetingNotFound = 'Reunión no encontrada';
  static const String meetingCreateFailed = 'Error al crear reunión';
  static const String meetingCancelFailed = 'Error al cancelar reunión';

  // Errores genéricos
  static const String unexpectedError = 'Error inesperado';
  static const String networkError = 'Error de conexión';
}
