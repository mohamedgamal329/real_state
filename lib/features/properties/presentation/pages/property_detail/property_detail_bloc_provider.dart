import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_share_cubit.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutation_cubit.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/users/domain/repositories/users_lookup_repository.dart';

import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_event.dart';

/// Provides [PropertyDetailBloc] with all dependencies already wired.
class PropertyDetailBlocProvider extends StatelessWidget {
  const PropertyDetailBlocProvider({
    super.key,
    required this.propertyId,
    required this.child,
  });

  final String propertyId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mutationCubitFactory = context
        .read<PropertyMutationCubit Function()>();
    final shareCubitFactory = context.read<PropertyShareCubit Function()>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<PropertyMutationCubit>(
          create: (context) => mutationCubitFactory(),
        ),
        BlocProvider<PropertyShareCubit>(
          create: (context) => shareCubitFactory(),
        ),
        BlocProvider<PropertyDetailBloc>(
          create: (context) => PropertyDetailBloc(
            context.read<PropertiesRepository>(),
            context.read<AccessRequestsRepository>(),
            context.read<AuthRepositoryDomain>(),
            context.read<NotificationsRepository>(),
            context.read<UsersLookupRepository>(),
            context.read<PropertyMutationCubit>(),
            context.read<PropertyShareCubit>(),
            context.read<PropertyMutationsBloc>(),
          )..add(PropertyDetailStarted(propertyId)),
        ),
      ],
      child: child,
    );
  }
}
