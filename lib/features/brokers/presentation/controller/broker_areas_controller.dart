import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/usecases/get_broker_areas_usecase.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_event.dart';
import 'package:real_state/features/properties/domain/services/property_mutations_stream.dart';

class BrokerAreasController {
  final GetBrokerAreasUseCase _getBrokerAreas;
  final LocationAreasRepository _areasRepo;
  final AuthRepositoryDomain _auth;
  final PropertyMutationsStream _mutations;

  BrokerAreasController(
    this._getBrokerAreas,
    this._areasRepo,
    this._auth,
    this._mutations,
  );

  BrokerAreasBloc createBloc(String brokerId) {
    return BrokerAreasBloc(_getBrokerAreas, _areasRepo, _auth, _mutations)
      ..add(BrokerAreasRequested(brokerId));
  }
}
