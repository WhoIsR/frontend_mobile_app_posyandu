enum UserRole { kader, bidan }

class AppUser {
  const AppUser({
    required this.id,
    required this.nama,
    required this.nikNip,
    required this.role,
    this.posyanduId,
  });

  final int id;
  final String nama;
  final String nikNip;
  final UserRole role;
  final int? posyanduId;
}
