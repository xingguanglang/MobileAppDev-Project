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
    final exists = await _repo.isUsernameTaken(username);
    if (exists) {
      emit(state.copyWith(loading: false, error: 'username already exists'));
      return;
    }
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
    emit(UserState(loading: true));
    try {
      final user = await _repo.signIn(username, password);
      if (user != null) {
        emit(state.copyWith(loading: false, user: user));
      } else {
        emit(UserState(loading: false, error: 'Invalid credentials'));
      }
    } catch (e) {
      emit(UserState(loading: false, error: e.toString()));
    }
  }
  
  // logout current user, clear user state
  Future<void> logout() async {
    emit(UserState());
  }

  /// Upgrade current user to premium
  Future<void> upgradeToPremium() async {
    final currentUser = state.user;
    if (currentUser == null) return;
    final premiumUser = AppUser(
      id: currentUser.id,
      username: currentUser.username,
      password: currentUser.password,
      userType: AppUser.userTypePremium,
    );
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repo.createUser(premiumUser);
      emit(state.copyWith(loading: false, user: premiumUser));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
