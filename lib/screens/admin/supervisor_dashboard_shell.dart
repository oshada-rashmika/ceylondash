import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/admin_navigation_bloc.dart';
import 'bloc/admin_navigation_event.dart';
import 'bloc/admin_navigation_state.dart';
import 'modules/analytics_module.dart';
import 'modules/promotions_module.dart';
import 'modules/agent_management_module.dart';
import 'modules/live_support_module.dart';
import 'modules/operations_map_module.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class SupervisorDashboardShell extends StatelessWidget {
  const SupervisorDashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminNavigationBloc(),
      child: const SupervisorDashboardView(),
    );
  }
}

class SupervisorDashboardView extends StatelessWidget {
  const SupervisorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final db = DatabaseService();

    return BlocBuilder<AdminNavigationBloc, AdminNavigationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: StreamBuilder<UserModel?>(
              stream: user != null ? db.streamUser(user.uid) : const Stream.empty(),
              builder: (context, snapshot) {
                final name = snapshot.data?.name ?? 'Supervisor';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CeylonDash',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Welcome back, $name',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                );
              }
            ),
            actions: [
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
              const SizedBox(width: 8),
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
                  selectedLabelTextStyle: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics_rounded, color: Colors.blueAccent),
                      label: Text('Analytics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_offer_outlined),
                      selectedIcon: Icon(Icons.local_offer_rounded, color: Colors.blueAccent),
                      label: Text('Promotions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group_rounded, color: Colors.blueAccent),
                      label: Text('Agents'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      selectedIcon: Icon(Icons.support_agent_rounded, color: Colors.blueAccent),
                      label: Text('Support'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded, color: Colors.blueAccent),
                      label: Text('Map'),
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
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  indicatorColor: Colors.blueAccent.withAlpha(40),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics_rounded, color: Colors.blueAccent),
                      label: 'Analytics',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.local_offer_outlined),
                      selectedIcon: Icon(Icons.local_offer_rounded, color: Colors.blueAccent),
                      label: 'Promos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group_rounded, color: Colors.blueAccent),
                      label: 'Agents',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      selectedIcon: Icon(Icons.support_agent_rounded, color: Colors.blueAccent),
                      label: 'Support',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded, color: Colors.blueAccent),
                      label: 'Map',
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
      case 4:
        return const OperationsMapModule();
      default:
        return const AnalyticsModule();
    }
  }
}
