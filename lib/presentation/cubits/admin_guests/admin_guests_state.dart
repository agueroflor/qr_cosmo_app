part of 'admin_guests_cubit.dart';

sealed class AdminGuestsState extends Equatable {
  const AdminGuestsState();

  @override
  List<Object?> get props => [];
}

class AdminGuestsInitial extends AdminGuestsState {
  const AdminGuestsInitial();
}

class AdminGuestsLoading extends AdminGuestsState {
  const AdminGuestsLoading();
}

class AdminGuestsLoaded extends AdminGuestsState {
  final List<GuestModel> guests;

  const AdminGuestsLoaded(this.guests);

  @override
  List<Object?> get props => [guests];
}

class AdminGuestsError extends AdminGuestsState {
  final String message;

  const AdminGuestsError(this.message);

  @override
  List<Object?> get props => [message];
}
