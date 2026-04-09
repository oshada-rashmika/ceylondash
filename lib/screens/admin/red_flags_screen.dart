import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/red_flags_bloc.dart';
import 'bloc/red_flags_event.dart';
import 'bloc/red_flags_state.dart';
import '../../../utils/fraud_detection_engine.dart';
import 'package:intl/intl.dart';

class RedFlagsScreen extends StatelessWidget {
  const RedFlagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RedFlagsBloc()..add(FetchRedFlags()),
      child: const RedFlagsView(),
    );
  }
}

class RedFlagsView extends StatelessWidget {
  const RedFlagsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Anomaly Intelligence', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RedFlagsBloc>().add(FetchRedFlags()),
          ),
        ],
      ),
      body: BlocBuilder<RedFlagsBloc, RedFlagsState>(
        builder: (context, state) {
          if (state is RedFlagsLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          } else if (state is RedFlagsError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is RedFlagsLoaded) {
            if (state.flags.isEmpty) {
              return _buildEmptyState();
            }
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shield_outlined, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'No Anomalies Detected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          Text('Your logistics network is running clean.'),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, RedFlagsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(state),
          const SizedBox(height: 32),
          const Text(
            'Recent Red Flags',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.flags.length,
            itemBuilder: (context, index) {
              final flag = state.flags[index];
              return _buildFlagItem(flag);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(RedFlagsLoaded state) {
    final criticalCount = state.flags.where((f) => f.severity == 'High').length;
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Flags',
            state.flags.length.toString(),
            Icons.flag_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Critical',
            criticalCount.toString(),
            Icons.warning_amber_rounded,
            Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFlagItem(RedFlag flag) {
    final color = flag.severity == 'High' ? Colors.redAccent : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
            child: Icon(_getIconForType(flag.type), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(flag.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      DateFormat('MMM d, HH:mm').format(flag.timestamp),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(flag.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'ID: ${flag.entityId}',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: Colors.blueGrey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        flag.severity,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(AnomalyType type) {
    switch (type) {
      case AnomalyType.speedHack:
        return Icons.speed_rounded;
      case AnomalyType.gpsSpoofing:
        return Icons.wrong_location_rounded;
      case AnomalyType.highReturnRate:
        return Icons.assignment_return_rounded;
    }
  }
}
