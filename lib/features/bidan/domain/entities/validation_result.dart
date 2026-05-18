class ValidationResult {
  const ValidationResult({
    required this.id,
    required this.referralId,
    required this.decision,
  });

  final int id;
  final int referralId;
  final String decision;
}
