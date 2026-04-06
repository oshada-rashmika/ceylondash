abstract class AdminNavigationEvent {}

class TabChanged extends AdminNavigationEvent {
  final int tabIndex;
  TabChanged(this.tabIndex);
}
