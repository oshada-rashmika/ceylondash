import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/agents_bloc.dart';
import '../../../../models/user_model.dart';
import 'package:uuid/uuid.dart';

class AgentManagementModule extends StatelessWidget {
  const AgentManagementModule({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AgentsBloc()..add(LoadAgents()),
      child: const AgentsView(),
    );
  }
}

class AgentsView extends StatelessWidget {
  const AgentsView({super.key});

  Future<void> _showAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Support Agent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Work Email')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final agent = UserModel(
                  uid: const Uuid().v4(),
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  email: emailCtrl.text,
                  role: 'agent',
                  fcmToken: '',
                );
                context.read<AgentsBloc>().add(AddAgent(agent));
                Navigator.pop(ctx);
              },
              child: const Text('Provision Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: const Text('Enlist Agent', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_rounded),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<AgentsBloc, AgentsState>(
                  builder: (context, state) {
                    if (state is AgentsLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    } else if (state is AgentsError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is AgentsLoaded) {
                      if (state.agents.isEmpty) {
                        return _buildEmptyState();
                      }
                      return ListView.builder(
                        itemCount: state.agents.length,
                        itemBuilder: (context, index) {
                          return _buildAgentCard(context, state.agents[index]);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Directory',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black.withAlpha(220),
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your support and operations team',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(BuildContext context, UserModel agent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.blueAccent, size: 30),
        ),
        title: Text(
          agent.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agent ID: CD-${agent.uid.substring(0, 4).toUpperCase()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(agent.email ?? 'No email', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              context.read<AgentsBloc>().add(DeactivateAgent(agent.uid));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.withAlpha(80)),
          const SizedBox(height: 24),
          const Text(
            'Unit Empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enlist support agents to start managing chats.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
