import 'package:real_state/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_bloc.dart';
import 'package:real_state/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_event.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/properties/domain/services/property_mutations_stream.dart';
import 'package:real_state/features/properties/domain/usecases/get_broker_properties_page_usecase.dart';

class BrokerAreaPropertiesController {
  final GetBrokerPropertiesPageUseCase _getBrokerPage;
  final PropertyMutationsStream _mutations;

  BrokerAreaPropertiesController(this._getBrokerPage, this._mutations);

  BrokerAreaPropertiesBloc createBloc({
    required String brokerId,
    required String areaId,
    required PropertyFilter filter,
  }) {
    return BrokerAreaPropertiesBloc(
      _getBrokerPage,
      _mutations,
      brokerId,
      areaId,
    )..add(
      BrokerAreaPropertiesStarted(
        brokerId: brokerId,
        areaId: areaId,
        filter: filter,
      ),
    );
  }
}
