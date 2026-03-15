class AccountRecord {
  const AccountRecord({
    required this.id,
    required this.name,
    required this.currency,
    required this.initialBalance,
    this.currentBalance,
  });

  final String id;
  final String name;
  final String currency;
  final double initialBalance;
  final double? currentBalance;
}
