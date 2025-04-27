import 'package:iotframework/core/error/failures.dart';

/// A class that represents the result of an operation that can either succeed with
/// a value of type [T] or fail with a [Failure].
class Result<T> {
  final T? _value;
  final Failure? _failure;

  const Result._({T? value, Failure? failure})
      : _value = value,
        _failure = failure;

  /// Creates a [Result] that represents a successful operation with [value].
  factory Result.success(T value) => Result._(value: value);

  /// Creates a [Result] that represents a failed operation with [failure].
  factory Result.failure(Failure failure) => Result._(failure: failure);

  /// Returns true if this result represents a successful operation.
  bool get isSuccess => _failure == null;

  /// Returns true if this result represents a failed operation.
  bool get isFailure => _failure != null;

  /// Returns the value of this result if it represents a successful operation,
  /// otherwise throws an exception.
  T get value {
    if (isSuccess) {
      return _value as T;
    }
    throw Exception('Cannot get value of a failed result');
  }

  /// Returns the failure of this result if it represents a failed operation,
  /// otherwise throws an exception.
  Failure get failure {
    if (isFailure) {
      return _failure!;
    }
    throw Exception('Cannot get failure of a successful result');
  }

  /// Executes [onSuccess] if this result represents a successful operation,
  /// otherwise executes [onFailure].
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    if (isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onFailure(_failure!);
    }
  }

  /// Maps the value of this result to a new value using [transform] if this
  /// result represents a successful operation, otherwise returns a new [Result]
  /// with the same failure.
  Result<R> map<R>(R Function(T value) transform) {
    if (isSuccess) {
      return Result.success(transform(_value as T));
    } else {
      return Result.failure(_failure!);
    }
  }
}
