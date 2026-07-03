import 'package:flutter/material.dart';

import '../models/production_security_model.dart';
import '../services/production_security_service.dart';
import '../services/release_monitoring_service.dart';

class ProductionSecurityScreen extends StatefulWidget {
  const ProductionSecurityScreen({super.key});

  @override
  State<ProductionSecurityScreen> createState() => _ProductionSecurityScreenState();
}

class _ProductionSecurityScreenState extends State<ProductionSecurityScreen> {
  late Future<ProductionSecurityPolicyModel?> _policyFuture;
  Future<ProductionSecurityStatusModel?>? _statusFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = ProductionSecurityService.instance.loadPolicy();
  }

  Future<void> _reportPrototypeError() async {
    try {
      throw StateError('Phase 35 prototype crash monitoring test');
    } catch (error, stackTrace) {
      await ReleaseMonitoringService.instance.recordError(error, stackTrace);
      await ProductionSecurityService.instance.reportCrashPrototype(
        error: error,
        stackTrace: stackTrace,
        screen: 'production_security_screen',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prototype error was recorded through the monitoring pipeline.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Production Security & Scale')),
      body: FutureBuilder<ProductionSecurityPolicyModel?>(
        future: _policyFuture,
        builder: (context, snapshot) {
          final policy = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (policy == null) {
            return const _OfflineSecuritySummary();
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(policy: policy),
              const SizedBox(height: 12),
              _ControlTile(
                title: 'Secure token storage',
                passed: policy.secureTokenStorageRequired,
                subtitle: 'Tokens are routed through SecureTokenStorageService.',
              ),
              _ControlTile(
                title: 'API rate limiting',
                passed: policy.rateLimitingEnabled,
                subtitle: '${policy.rateLimiting['maxRequests']} requests per window; auth has a stricter limit.',
              ),
              _ControlTile(
                title: 'Request validation',
                passed: policy.requestValidationEnabled,
                subtitle: 'Invalid JSON, oversized bodies, and invalid write-body shapes are rejected.',
              ),
              _ControlTile(
                title: 'Privacy and retention',
                passed: true,
                subtitle: 'Admin analytics and audit surfaces redact sensitive fields.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _statusFuture = ProductionSecurityService.instance.loadAdminStatus();
                  });
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Load admin security status'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _reportPrototypeError,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test crash/error monitoring placeholder'),
              ),
              if (_statusFuture != null) ...[
                const SizedBox(height: 12),
                FutureBuilder<ProductionSecurityStatusModel?>(
                  future: _statusFuture,
                  builder: (context, statusSnapshot) {
                    final status = statusSnapshot.data;
                    if (statusSnapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (status == null) {
                      return const Text('Admin status requires an admin token from secure storage.');
                    }
                    return _StatusCard(status: status);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OfflineSecuritySummary extends StatelessWidget {
  const _OfflineSecuritySummary();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Security APIs are unavailable because the backend base URL is not configured. Local game mode continues to work; connect the API to view live production security status.',
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.policy});

  final ProductionSecurityPolicyModel policy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase 35 policy v${policy.version}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Production readiness controls are additive and do not change the normal individual game flow.'),
          ],
        ),
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.title,
    required this.passed,
    required this.subtitle,
  });

  final String title;
  final bool passed;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(passed ? Icons.verified_user : Icons.warning_amber),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final ProductionSecurityStatusModel status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin status: ${status.status}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${status.passedControlCount}/11 controls active'),
          ],
        ),
      ),
    );
  }
}
