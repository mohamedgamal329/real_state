import 'failure.dart';

class ValidationFailure extends Failure {
  const ValidationFailure({super.error, super.stackTrace});
}
