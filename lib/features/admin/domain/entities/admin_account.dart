class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.name,
    required this.nikNip,
    required this.role,
    required this.status,
    this.posyanduId,
  });

  final int id;
  final String name;
  final String nikNip;
  final String role;
  final String status;
  final int? posyanduId;
}
