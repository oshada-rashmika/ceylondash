import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/admin_navigation_bloc.dart';
import 'bloc/admin_navigation_event.dart';
import 'bloc/admin_navigation_state.dart';
import 'modules/analytics_module.dart';
import 'modules/promotions_module.dart';
import 'modules/agent_management_module.dart';
import 'modules/live_support_module.dart';

class AdminDashboardShell extends StatelessWidget {
  const AdminDashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminNavigationBloc(),
      child: const AdminDashboardView(),
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminNavigationBloc, AdminNavigationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Welcome back, Admin',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black54),
                onPressed: () {
                  // TODO: Handle logout
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
          body: Row(
            children: [
              if (MediaQuery.of(context).size.width >= 800)
                NavigationRail(
                  selectedIndex: state.tabIndex,
                  onDestinationSelected: (int index) {
                    context.read<AdminNavigationBloc>().add(TabChanged(index));
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: Text('Analytics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_offer_outlined),
                      selectedIcon: Icon(Icons.local_offer),
                      label: Text('Promotions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group),
                      label: Text('Agents'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      selectedIcon: Icon(Icons.support_agent),
                      label: Text('Support'),
                    ),
                  ],
                ),
              if (MediaQuery.of(context).size.width >= 800)
                const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _buildBody(state.tabIndex),
              ),
            ],
          ),
          bottomNavigationBar: MediaQuery.of(context).size.width < 800
              ? NavigationBar(
                  selectedIndex: state.tabIndex,
                  onDestinationSelected: (int index) {
                    context.read<AdminNavigationBloc>().add(TabChanged(index));
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: 'Analytics',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.local_offer_outlined),
                      selectedIcon: Icon(Icons.local_offer),
                      label: 'Promos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group),
                      label: 'Agents',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      selectedIcon: Icon(Icons.support_agent),
                      label: 'Support',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const AnalyticsModule();
      case 1:
        return const PromotionsModule();
      case 2:
        return const AgentManagementModule();
      case 3:
        return const LiveSupportModule();
      default:
        return const AnalyticsModule();
    }
  }
}
