import 'package:bloc/bloc.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserState {
  final bool loading;
  final AppUser? user;
  final String? error;

  UserState({this.loading = false, this.user, this.error});

  UserState copyWith({bool? loading, AppUser? user, String? error}) {
    return UserState(
      loading: loading ?? this.loading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class UserCubit extends Cubit<UserState> {
  final UserRepository _repo;

  UserCubit(this._repo) : super(UserState());

  Future<void> createUser(String username, String password, String userType) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final id = await _repo.createUserAutoId(
        AppUser(id: '', username: username, password: password, userType: userType),
      );
      final user = AppUser(id: id, username: username, password: password, userType: userType);
      emit(state.copyWith(loading: false, user: user));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> loadUser(String id) async {
    emit(state.copyWith(loading: true));
    final user = await _repo.getUser(id);
    if (user != null) {
      emit(state.copyWith(loading: false, user: user));
    } else {
      emit(state.copyWith(loading: false, error: 'User not found'));
    }
  }

  Future<void> signIn(String username, String password) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final user = await _repo.signIn(username, password);
      if (user != null) {
        emit(state.copyWith(loading: false, user: user));
      } else {
        emit(state.copyWith(loading: false, error: 'Invalid credentials'));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
