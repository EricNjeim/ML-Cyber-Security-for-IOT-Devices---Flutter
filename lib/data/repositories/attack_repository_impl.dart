import 'package:dio/dio.dart';
import 'package:iotframework/core/error/exceptions.dart';
import 'package:iotframework/core/error/failures.dart';
import 'package:iotframework/core/network/network_service.dart';
import 'package:iotframework/core/util/result.dart';
import 'package:iotframework/domain/models/ongoing_attack.dart';
import 'package:iotframework/domain/repositories/attack_repository.dart';
import 'package:logger/logger.dart';

/// Implementation of AttackRepository for handling ongoing attacks
class AttackRepositoryImpl implements AttackRepository {
  final NetworkService _networkService;
  final Logger? _logger;

  AttackRepositoryImpl({
    required NetworkService networkService,
    Logger? logger,
  })  : _networkService = networkService,
        _logger = logger;

  @override
  Future<Result<List<OngoingAttack>>> getOngoingAttacks() async {
    try {
      final response = await _networkService.get('/attacks/ongoing');

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List<dynamic> attacksData;

        if (data is List) {
          attacksData = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('attacks')) {
            attacksData = data['attacks'] as List;
          } else if (data.containsKey('data')) {
            attacksData = data['data'] as List;
          } else {
            _logger?.w('Unexpected response format: $data');
            attacksData = [];
          }
        } else {
          _logger?.w('Unexpected response format: $data');
          attacksData = [];
        }

        final ongoingAttacks = attacksData
            .map((item) => OngoingAttack.fromJson(item as Map<String, dynamic>))
            .toList();

        return Result.success(ongoingAttacks);
      } else {
        _logger?.e('Error fetching ongoing attacks: ${response.statusCode}');
        return Result.failure(
          ServerFailure(
              message:
                  'Failed to fetch ongoing attacks: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _logger?.e('Dio error fetching ongoing attacks', error: e);
      return Result.failure(
        ServerFailure(message: 'Network error: ${e.message}'),
      );
    } on ServerException {
      return Result.failure(
        const ServerFailure(message: 'Server error'),
      );
    } on UnauthorizedException {
      return Result.failure(
        const AuthenticationFailure(message: 'Authentication error'),
      );
    } catch (e) {
      _logger?.e('Unexpected error fetching ongoing attacks', error: e);
      return Result.failure(
        ServerFailure(message: 'Unexpected error: $e'),
      );
    }
  }

  @override
  Future<Result<bool>> resolveAttack(int attackId) async {
    try {
      final response = await _networkService.patch(
        '/attacks/$attackId/resolve',
      );

      if (response.statusCode == 200) {
        return Result.success(true);
      } else {
        _logger?.e('Error resolving attack: ${response.statusCode}');
        return Result.failure(
          ServerFailure(
              message: 'Failed to resolve attack: ${response.statusCode}'),
        );
      }
    } on DioException catch (e) {
      _logger?.e('Dio error resolving attack', error: e);
      return Result.failure(
        ServerFailure(message: 'Network error: ${e.message}'),
      );
    } on ServerException {
      return Result.failure(
        const ServerFailure(message: 'Server error'),
      );
    } on UnauthorizedException {
      return Result.failure(
        const AuthenticationFailure(message: 'Authentication error'),
      );
    } catch (e) {
      _logger?.e('Unexpected error resolving attack', error: e);
      return Result.failure(
        ServerFailure(message: 'Unexpected error: $e'),
      );
    }
  }
}
 