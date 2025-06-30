import 'dart:async';
import 'package:flutter/foundation.dart';

/// Dependency management and race condition prevention
class InitializationCoordinator {
  static final InitializationCoordinator _instance = InitializationCoordinator._internal();
  factory InitializationCoordinator() => _instance;
  InitializationCoordinator._internal();

  final Map<String, ServiceStatus> _serviceStatus = {};
  final Map<String, Completer<void>> _initializationCompleters = {};
  final Map<String, List<String>> _dependencies = {};

  /// Register a service with its dependencies
  void registerService(String serviceName, {List<String> dependencies = const []}) {
    _serviceStatus[serviceName] = ServiceStatus.registered;
    _dependencies[serviceName] = List.from(dependencies);
    _initializationCompleters[serviceName] = Completer<void>();
    
    if (kDebugMode) debugPrint('[InitializationCoordinator] Registered service: $serviceName');
  }

  /// Mark service as initializing
  void markServiceInitializing(String serviceName) {
    if (!_serviceStatus.containsKey(serviceName)) {
      registerService(serviceName);
    }
    
    _serviceStatus[serviceName] = ServiceStatus.initializing;
    if (kDebugMode) debugPrint('[InitializationCoordinator] Service $serviceName is initializing');
  }

  /// Mark service as initialized
  void markServiceInitialized(String serviceName) {
    _serviceStatus[serviceName] = ServiceStatus.initialized;
    _initializationCompleters[serviceName]?.complete();
    
    if (kDebugMode) debugPrint('[InitializationCoordinator] Service $serviceName initialized');
  }

  /// Mark service as failed to initialize
  void markServiceFailed(String serviceName, dynamic error) {
    _serviceStatus[serviceName] = ServiceStatus.failed;
    _initializationCompleters[serviceName]?.completeError(error);
    
    if (kDebugMode) debugPrint('[InitializationCoordinator] ERROR: Service $serviceName failed');
  }

  /// Wait for a service to be initialized
  Future<void> waitForService(String serviceName, {Duration? timeout}) async {
    if (!_serviceStatus.containsKey(serviceName)) {
      throw ServiceNotRegisteredException('Service $serviceName is not registered');
    }

    final status = _serviceStatus[serviceName]!;
    if (status == ServiceStatus.initialized) {
      return; // Already initialized
    }

    if (status == ServiceStatus.failed) {
      throw ServiceInitializationException('Service $serviceName failed to initialize');
    }

    final completer = _initializationCompleters[serviceName]!;
    
    if (timeout != null) {
      await completer.future.timeout(timeout);
    } else {
      await completer.future;
    }
  }

  /// Wait for dependencies to be ready
  Future<void> waitForDependencies(String serviceName) async {
    final dependencies = _dependencies[serviceName] ?? [];
    
    for (final dependency in dependencies) {
      await waitForService(dependency);
    }
    
    if (kDebugMode) debugPrint('[InitializationCoordinator] All dependencies ready for $serviceName');
  }

  /// Get service status
  ServiceStatus getServiceStatus(String serviceName) {
    return _serviceStatus[serviceName] ?? ServiceStatus.notRegistered;
  }

  /// Get initialization report
  Map<String, ServiceStatus> getInitializationReport() {
    return Map.from(_serviceStatus);
  }

  /// Check if all services are initialized
  bool get allServicesInitialized {
    return _serviceStatus.values.every((status) => status == ServiceStatus.initialized);
  }
}

enum ServiceStatus { notRegistered, registered, initializing, initialized, failed }

class ServiceNotRegisteredException implements Exception {
  final String message;
  ServiceNotRegisteredException(this.message);
  @override
  String toString() => 'ServiceNotRegisteredException: $message';
}

class ServiceInitializationException implements Exception {
  final String message;
  ServiceInitializationException(this.message);
  @override
  String toString() => 'ServiceInitializationException: $message';
}
