/// Represents the scope of an update or delete operation on a recurring event.
enum UpdateScope {
  /// Update/delete only this specific event instance.
  thisEvent('THIS_EVENT'),

  /// Update/delete all future events in the recurring series.
  allEvents('ALL_EVENTS');

  const UpdateScope(this.apiValue);
  final String apiValue;

  static UpdateScope fromApi(String value) {
    final normalized = value.toUpperCase();
    return UpdateScope.values.firstWhere(
      (scope) => scope.apiValue == normalized,
      orElse: () => UpdateScope.thisEvent,
    );
  }
}
