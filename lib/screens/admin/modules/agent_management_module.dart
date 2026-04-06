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

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Agent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
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
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agent Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<AgentsBloc, AgentsState>(
                  builder: (context, state) {
                    if (state is AgentsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is AgentsError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is AgentsLoaded) {
                      if (state.agents.isEmpty) {
                        return const Center(child: Text('No active agents'));
                      }
                      return ListView.builder(
                        itemCount: state.agents.length,
                        itemBuilder: (context, index) {
                          final agent = state.agents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF141E30),
                                child: Icon(Icons.support_agent, color: Colors.white),
                              ),
                              title: Text(agent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${agent.email ?? 'No email'}\n${agent.phone}'),
                              isThreeLine: true,
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.person_off, size: 16),
                                label: const Text('Deactivate'),
                                onPressed: () {
                                  context.read<AgentsBloc>().add(DeactivateAgent(agent.uid));
                                },
                              ),
                            ),
                          );
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
}
