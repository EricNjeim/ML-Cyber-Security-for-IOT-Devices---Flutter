import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:iotframework/core/error/exceptions.dart';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/network/network_service.dart';
import 'package:iotframework/core/util/constants.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/data/models/network_traffic_model.dart';
import 'package:iotframework/domain/models/network_traffic.dart';
import 'package:iotframework/domain/repositories/network_traffic_repository.dart';
import 'package:logger/logger.dart';

/// Implementation of [NetworkTrafficRepository]
class NetworkTrafficRepositoryImpl implements NetworkTrafficRepository {
  final NetworkService _networkService;
  final Logger _logger;

  NetworkTrafficRepositoryImpl({
    required NetworkService networkService,
    required Logger logger,
  })  : _networkService = networkService,
        _logger = logger;

  @override
  Future<Result<List<NetworkTraffic>>> getRecentTraffic(int limit) async {
    try {
      final response = await _networkService.get(
        '/network-traffic',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List<dynamic> trafficData;

        // Handle both Map and List response formats
        if (data is List) {
          trafficData = data;
        } else if (data is Map<String, dynamic>) {
          // Check for 'entries' field first (based on the actual API response)
          if (data.containsKey('entries') && data['entries'] is List) {
            trafficData = data['entries'] as List;
            _logger.d('Found ${trafficData.length} items in entries field');
          }
          // Fallback to 'data' field if entries doesn't exist
          else if (data.containsKey('data') && data['data'] is List) {
            trafficData = data['data'] as List;
            _logger.d('Found ${trafficData.length} items in data field');
          } else {
            _logger.w(
                'Response is Map but does not contain entries or data List field: $data');
            trafficData = [];
          }
        } else {
          _logger.w('Unexpected response type: ${data.runtimeType}');
          trafficData = [];
        }

        final networkTraffic = trafficData
            .map(
                (item) => NetworkTraffic.fromJson(item as Map<String, dynamic>))
            .toList();

        return Result.success(networkTraffic);
      } else {
        _logger.e('Error fetching network traffic: ${response.statusCode}');
        return Result.failure(
          ServerFailure(
              message:
                  'Failed to fetch network traffic: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _logger.e('Dio error fetching network traffic', error: e);
      return Result.failure(
        ServerFailure(message: 'Network error: ${e.message}'),
      );
    } catch (e) {
      _logger.e('Unexpected error fetching network traffic', error: e);
      return Result.failure(
        ServerFailure(message: 'Unexpected error: $e'),
      );
    }
  }

  @override
  Future<List<NetworkTraffic>> getNetworkTrafficLogs() async {
    try {
      final response = await _networkService.get('/network-traffic');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List<dynamic> trafficData;

        if (data is List) {
          trafficData = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('entries') && data['entries'] is List) {
            trafficData = data['entries'] as List;
          } else if (data.containsKey('data') && data['data'] is List) {
            trafficData = data['data'] as List;
          } else {
            trafficData = [];
          }
        } else {
          trafficData = [];
        }

        return trafficData
            .map(
                (item) => NetworkTraffic.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException();
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<NetworkTraffic>> getRecentAttacks() async {
    try {
      final response = await _networkService.get('/recent-attacks');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List<dynamic> trafficData;

        if (data is List) {
          trafficData = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('entries') && data['entries'] is List) {
            trafficData = data['entries'] as List;
          } else if (data.containsKey('data') && data['data'] is List) {
            trafficData = data['data'] as List;
          } else {
            trafficData = [];
          }
        } else {
          trafficData = [];
        }

        return trafficData
            .map(
                (item) => NetworkTraffic.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException();
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      throw ServerException();
    }
  }
}
