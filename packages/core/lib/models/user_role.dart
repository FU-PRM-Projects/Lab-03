/// Vai trò lưu ở `users/{uid}.role`. Người dùng app là [user]; [staff] và
/// [admin] làm việc trên web admin. Chỉ admin đổi vai trò, không ai tự đổi
/// vai trò của mình (firestore.rules).
enum UserRole {
  user(id: 'user', label: 'Người dùng'),
  staff(id: 'staff', label: 'Staff'),
  admin(id: 'admin', label: 'Admin');

  const UserRole({required this.id, required this.label});

  final String id;
  final String label;

  /// Được vào web admin.
  bool get canUseAdmin => this != user;

  /// Vai trò lạ hoặc thiếu coi như [user] (quyền thấp nhất).
  static UserRole fromId(String? id) {
    for (final role in values) {
      if (role.id == id) return role;
    }
    return user;
  }
}

/// Một dòng trong danh sách người dùng của web admin.
class UserSummary {
  const UserSummary({
    required this.uid,
    required this.role,
    this.displayName = '',
    this.email = '',
  });

  final String uid;
  final UserRole role;
  final String displayName;
  final String email;
}
