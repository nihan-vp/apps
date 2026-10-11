import 'package:flutter/material.dart';
import 'package:focuson_core/focuson_core.dart';
import 'package:focuson_models/focuson_models.dart';
import 'package:focuson_database/focuson_database.dart';
import 'package:focuson_design_system/focuson_design_system.dart';

class ExecutionHistoryScreen extends StatefulWidget {
  final FocusDatabase db;

  const ExecutionHistoryScreen({super.key, required this.db});

  @override
  State<ExecutionHistoryScreen> createState() => _ExecutionHistoryScreenState();
}

class _ExecutionHistoryScreenState extends State<ExecutionHistoryScreen> {
  late Future<List<AutomationExecution>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = widget.db.automationRepo.getExecutionHistory(limit: 50);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear History',
            onPressed: () async {
              await widget.db.automationRepo.clearExecutionHistory();
              _loadHistory();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AutomationExecution>>(
        future: _historyFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: FocusEmptyState(
                icon: Icons.history_toggle_off,
                title: 'No Automation Logs',
                message: 'Executed triggers and condition checks will appear here with execution metrics.',
              ),
            );
          }

          return ListView.separated(
            padding: FocusSpacing.insetAllMd,
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: FocusSpacing.sm),
            itemBuilder: (ctx, idx) {
              final log = logs[idx];
              final passed = log.conditionsPassed;
              final isDryRun = log.isDryRun;

              return FocusCard(
                borderColor: passed ? FocusColors.emeraldGreen.withOpacity(0.4) : FocusColors.darkBorder,
                padding: FocusSpacing.insetAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          passed ? Icons.check_circle : Icons.cancel,
                          color: passed ? FocusColors.emeraldGreen : FocusColors.darkTextSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: FocusSpacing.xs),
                        Expanded(
                          child: Text(
                            'Rule: ${log.ruleId}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        if (isDryRun)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: FocusColors.electricBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('DRY RUN', style: TextStyle(fontSize: 10, color: FocusColors.electricBlue, fontWeight: FontWeight.bold)),
                          ),
                        Text(
                          '${log.executionDurationMs} ms',
                          style: const TextStyle(fontSize: 11, color: FocusColors.darkTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: FocusSpacing.xs),
                    Text(
                      'Trigger: ${log.triggerDetails.isNotEmpty ? log.triggerDetails : "Internal"} • ${log.triggeredAt.toLocal().toString().substring(0, 16)}',
                      style: const TextStyle(fontSize: 12, color: FocusColors.darkTextSecondary),
                    ),
                    const SizedBox(height: FocusSpacing.xs),
                    Text(
                      'Action Outcome: ${log.actionResult}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (log.errorMessage != null && log.errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: FocusSpacing.xs),
                      Text(
                        'Error: ${log.errorMessage}',
                        style: const TextStyle(fontSize: 12, color: FocusColors.coralDanger),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
