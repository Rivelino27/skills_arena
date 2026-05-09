abstract class AppFailure {
  final String message;
  final String? code;

  const AppFailure({required this.message, this.code});
}

class AuthFailure extends AppFailure {
  const AuthFailure({required super.message, super.code});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Sem conexão com a internet.',
    super.code,
  });
}

class ServerFailure extends AppFailure {
  const ServerFailure({
    super.message = 'Erro no servidor. Tente novamente.',
    super.code,
  });
}

class StorageFailure extends AppFailure {
  const StorageFailure({required super.message, super.code});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Erro inesperado. Tente novamente.',
    super.code,
  });
}
