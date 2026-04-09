class AdminNavigationState {
  final int tabIndex;

  AdminNavigationState({required this.tabIndex});

  factory AdminNavigationState.initial() => AdminNavigationState(tabIndex: 0);
}
