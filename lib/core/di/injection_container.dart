import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:iotframework/core/auth/auth_redirect_service.dart';
import 'package:iotframework/core/network/network_service.dart';
import 'package:iotframework/core/util/constants.dart';
import 'package:iotframework/data/repositories/auth_repository_impl.dart';
import 'package:iotframework/data/repositories/network_traffic_repository_impl.dart';
import 'package:iotframework/data/repositories/device_repository_impl.dart';
import 'package:iotframework/data/repositories/recent_attacks_repository_impl.dart';
import 'package:iotframework/data/repositories/attack_repository_impl.dart';
import 'package:iotframework/domain/repositories/auth_repository.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';
import 'package:iotframework/domain/repositories/device_repository.dart';
import 'package:iotframework/domain/repositories/attack_repository.dart';
import 'package:iotframework/domain/usecases/auth/get_auth_headers.dart';
import 'package:iotframework/domain/usecases/auth/login.dart';
import 'package:iotframework/domain/usecases/auth/login_for_refresh.dart';
import 'package:iotframework/domain/usecases/network/get_network_traffic_logs.dart';
import 'package:iotframework/domain/usecases/network/get_recent_attacks.dart';
import 'package:iotframework/domain/usecases/devices/get_devices.dart';
import 'package:iotframework/domain/usecases/devices/ping_device.dart';
import 'package:iotframework/domain/usecases/devices/ping_all_devices.dart';
import 'package:iotframework/domain/usecases/attacks/get_ongoing_attacks.dart';
import 'package:iotframework/domain/usecases/attacks/resolve_attack.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iotframework/core/services/notification_service.dart';

/// This class is responsible for setting up the dependency injection container
class ServiceLocator {
  static final apiBaseUrlProvider = Provider<String>((ref) {
    return AppConstants.apiBaseUrl;
  });

  // Core
  static final loggerProvider = Provider<Logger>((ref) {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  });

  static final httpClientProvider = Provider<http.Client>((ref) {
    return http.Client();
  });

  static final dioProvider = Provider<Dio>((ref) {
    final baseUrl = ref.read(apiBaseUrlProvider);
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.json,
      ),
    );
  });

  // Repositories first
  static final authRepositoryProvider = Provider<AuthRepository>((ref) {
    return AuthRepositoryImpl(
      secureStorage: ref.read(secureStorageProvider),
      client: ref.read(httpClientProvider),
    );
  });

  // Auth headers provider next
  static final getAuthHeadersProvider = Provider<GetAuthHeaders>((ref) {
    return GetAuthHeaders(ref.read(authRepositoryProvider));
  });

  // Add login-based refresh usecase before network service
  static final loginForRefreshProvider = Provider<LoginForRefresh>((ref) {
    return LoginForRefresh(ref.read(authRepositoryProvider));
  });

  // Then network service that depends on auth repository
  static final networkServiceProvider = Provider<NetworkService>((ref) {
    return NetworkService(
      dio: ref.read(dioProvider),
      authRepository: ref.read(authRepositoryProvider),
      logger: ref.read(loggerProvider),
    );
  });

  // Add the AuthRedirectService provider after NetworkService
  static final authRedirectServiceProvider =
      Provider<AuthRedirectService>((ref) {
    return AuthRedirectService(
      networkService: ref.read(networkServiceProvider),
    );
  });

  // Then other repositories that depend on network service
  static final networkTrafficRepositoryProvider =
      Provider<NetworkTrafficRepository>((ref) {
    return NetworkTrafficRepositoryImpl(
      networkService: ref.read(networkServiceProvider),
      logger: ref.read(loggerProvider),
    );
  });

  // Add ongoing attacks repository
  static final attackRepositoryProvider = Provider<AttackRepository>((ref) {
    return AttackRepositoryImpl(
      networkService: ref.read(networkServiceProvider),
      logger: ref.read(loggerProvider),
    );
  });

  // Add recent attacks repository
  static final recentAttacksRepositoryProvider =
      Provider<NetworkTrafficRepository>((ref) {
    return RecentAttacksRepositoryImpl(
      networkService: ref.read(networkServiceProvider),
      logger: ref.read(loggerProvider),
    );
  });

  static final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
    return DeviceRepositoryImpl(
      networkService: ref.read(networkServiceProvider),
    );
  });

  // Use cases
  static final loginUseCaseProvider = Provider<Login>((ref) {
    return Login(ref.read(authRepositoryProvider));
  });

  static final getNetworkTrafficLogsProvider =
      Provider<GetNetworkTrafficLogs>((ref) {
    return GetNetworkTrafficLogs(ref.read(networkTrafficRepositoryProvider));
  });

  static final getRecentAttacksProvider = Provider<GetRecentAttacks>((ref) {
    return GetRecentAttacks(ref.read(networkTrafficRepositoryProvider));
  });

  static final getDevicesProvider = Provider<GetDevices>((ref) {
    return GetDevices(ref.read(deviceRepositoryProvider));
  });

  static final pingDeviceProvider = Provider<PingDevice>((ref) {
    return PingDevice(ref.read(deviceRepositoryProvider));
  });

  static final pingAllDevicesProvider = Provider<PingAllDevices>((ref) {
    return PingAllDevices(ref.read(deviceRepositoryProvider));
  });

  // Attack use cases
  static final getOngoingAttacksProvider = Provider<GetOngoingAttacks>((ref) {
    return GetOngoingAttacks(ref.read(attackRepositoryProvider));
  });

  static final resolveAttackProvider = Provider<ResolveAttack>((ref) {
    return ResolveAttack(ref.read(attackRepositoryProvider));
  });

  // Additional providers
  static final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
    return const FlutterSecureStorage();
  });

  // Notification service provider
  static final notificationServiceProvider =
      Provider<NotificationService>((ref) {
    return NotificationService(
      networkService: ref.read(networkServiceProvider),
      logger: ref.read(loggerProvider),
      authRepository: ref.read(authRepositoryProvider),
    );
  });
}
