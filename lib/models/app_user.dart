/// Người dùng đã đăng nhập, độc lập với SDK đăng nhập.
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);
}
