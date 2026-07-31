enum UserRole {
  customer,
  partner,
  deliveryAgent,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.partner:
        return 'Service Partner';
      case UserRole.deliveryAgent:
        return 'Delivery Agent';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}
