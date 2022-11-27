
T requireNotNull<T>(T? argument, [String? message]) {
  return ArgumentError.checkNotNull(argument, message);
}