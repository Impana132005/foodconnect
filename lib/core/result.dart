/// A generic result wrapper representing either a Success or a Failure.
/// Used to enforce predictable error handling throughout repositories and services.
abstract class Result<S, F> {
  const Result();

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;

  S? get successValue => isSuccess ? (this as Success<S, F>).value : null;
  F? get failureValue => isFailure ? (this as Failure<S, F>).error : null;

  T fold<T>(T Function(S success) onSuccess, T Function(F failure) onFailure) {
    if (this is Success<S, F>) {
      return onSuccess((this as Success<S, F>).value);
    } else if (this is Failure<S, F>) {
      return onFailure((this as Failure<S, F>).error);
    }
    throw AssertionError('Result must be either Success or Failure');
  }
}

class Success<S, F> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

class Failure<S, F> extends Result<S, F> {
  final F error;
  const Failure(this.error);
}
