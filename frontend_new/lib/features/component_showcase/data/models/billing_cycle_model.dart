/// BillingCycle - Billing Toggle의 청구 주기 정보
class BillingCycle {
  final String monthlyLabel;
  final String yearlyLabel;

  const BillingCycle({
    this.monthlyLabel = 'Billed monthly',
    this.yearlyLabel = 'Billed yearly',
  });

  /// Copy with
  BillingCycle copyWith({String? monthlyLabel, String? yearlyLabel}) {
    return BillingCycle(
      monthlyLabel: monthlyLabel ?? this.monthlyLabel,
      yearlyLabel: yearlyLabel ?? this.yearlyLabel,
    );
  }
}
