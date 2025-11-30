import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Servicios
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../services/transaction_service.dart';
import '../../services/loan_service.dart';
import '../../services/meeting_service.dart';
import '../../services/report_service.dart';

/// 🏗️ SERVICE LOCATOR - SINGLE SOURCE OF TRUTH
///
/// Gestiona TODAS las instancias de servicios en la app.
/// Patrón Singleton usando get_it.
///
/// Ventajas:
/// ✅ Un solo lugar para configurar dependencias
/// ✅ Fácil de testear (reemplazar con mocks)
/// ✅ Evita crear múltiples instancias de servicios
/// ✅ Estándar de la industria (Google, Airbnb, etc.)
final getIt = GetIt.instance;

/// 🚀 Inicializa TODOS los servicios de la app
///
/// IMPORTANTE: Llamar en main.dart ANTES de runApp()
///
/// Ejemplo:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp();
///
///   // ⭐ Inicializar servicios
///   setupServiceLocator();
///
///   runApp(MyApp());
/// }
/// ```
void setupServiceLocator() {
  // ==================== FIREBASE INSTANCES ====================
  // Singletons de Firebase (una sola instancia en toda la app)

  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }

  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  // ==================== SERVICIOS DE NEGOCIO ====================
  // Lazy Singleton: Se crean solo cuando se necesitan por primera vez

  // 🔐 AUTH SERVICE
  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerLazySingleton<AuthService>(
      () => AuthService(
        auth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    );
  }

  // 👥 GROUP SERVICE
  if (!getIt.isRegistered<GroupService>()) {
    getIt.registerLazySingleton<GroupService>(
      () => GroupService(
        firestore: getIt<FirebaseFirestore>(),
        getCurrentUserId: () => getIt<AuthService>().currentUserId,
      ),
    );
  }

  // 💰 TRANSACTION SERVICE
  if (!getIt.isRegistered<TransactionService>()) {
    getIt.registerLazySingleton<TransactionService>(
      () => TransactionService(firestore: getIt<FirebaseFirestore>()),
    );
  }

  // 🏦 LOAN SERVICE
  if (!getIt.isRegistered<LoanService>()) {
    getIt.registerLazySingleton<LoanService>(
      () => LoanService(firestore: getIt<FirebaseFirestore>()),
    );
  }

  // 📅 MEETING SERVICE
  if (!getIt.isRegistered<MeetingService>()) {
    getIt.registerLazySingleton<MeetingService>(
      () => MeetingService(firestore: getIt<FirebaseFirestore>()),
    );
  }

  // 📊 REPORT SERVICE
  if (!getIt.isRegistered<ReportService>()) {
    getIt.registerLazySingleton<ReportService>(
      () => ReportService(firestore: getIt<FirebaseFirestore>()),
    );
  }
}

/// 🔄 Resetea TODOS los servicios (útil para testing)
///
/// Ejemplo en tests:
/// ```dart
/// setUp(() {
///   resetServiceLocator();
///   setupServiceLocator();
/// });
/// ```
void resetServiceLocator() {
  getIt.reset();
}

/// 🧪 Configura servicios MOCK para testing
///
/// Ejemplo:
/// ```dart
/// void main() {
///   setUpAll(() {
///     setupMockServiceLocator(
///       mockAuthService: MockAuthService(),
///       mockGroupService: MockGroupService(),
///     );
///   });
/// }
/// ```
void setupMockServiceLocator({
  AuthService? mockAuthService,
  GroupService? mockGroupService,
  TransactionService? mockTransactionService,
  LoanService? mockLoanService,
  MeetingService? mockMeetingService,
  ReportService? mockReportService,
}) {
  resetServiceLocator();

  // Registrar mocks
  if (mockAuthService != null) {
    getIt.registerSingleton<AuthService>(mockAuthService);
  }

  if (mockGroupService != null) {
    getIt.registerSingleton<GroupService>(mockGroupService);
  }

  if (mockTransactionService != null) {
    getIt.registerSingleton<TransactionService>(mockTransactionService);
  }

  if (mockLoanService != null) {
    getIt.registerSingleton<LoanService>(mockLoanService);
  }

  if (mockMeetingService != null) {
    getIt.registerSingleton<MeetingService>(mockMeetingService);
  }

  if (mockReportService != null) {
    getIt.registerSingleton<ReportService>(mockReportService);
  }
}
