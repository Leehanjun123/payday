class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;

  void setUser(User user) {
    _currentUser = user;
  }

  void logout() {
    _currentUser = null;
  }
}

class User {
  final String id;
  final String email;
  final String? token;

  User({
    required this.id,
    required this.email,
    this.token,
  });
}