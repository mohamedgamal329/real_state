import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final Object? error;
  final StackTrace? stackTrace;

  const Failure({this.error, this.stackTrace});

  @override
  List<Object?> get props => [error, stackTrace];
}
