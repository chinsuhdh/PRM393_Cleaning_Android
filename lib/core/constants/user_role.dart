enum UserRole { client, worker, admin }

extension UserRoleApi on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.worker:
        return 'Worker';
      case UserRole.client:
        return 'Client';
    }
  }
}
