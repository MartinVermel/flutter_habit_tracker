import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_sync_service.dart';

/// Small chip in the AppBar showing cloud sync status.
///
/// Three states:
///   ☁ synced    — signed in, Firestore reachable
///   ↻ syncing   — write in flight
///   ✕ offline   — not signed in (anonymous) — taps open account upgrade flow
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isAnon = user == null || user.isAnonymous;

        if (isAnon) {
          return _Chip(
            icon: Icons.cloud_off_outlined,
            label: 'Local only',
            color: cs.onSurfaceVariant,
            onTap: () => _showUpgradeDialog(context),
          );
        }

        // Signed in — listen to Firestore connection state
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreSyncService().habitsStream(),
          builder: (context, fsSnap) {
            if (fsSnap.connectionState == ConnectionState.waiting) {
              return _Chip(
                icon: Icons.sync_rounded,
                label: 'Syncing…',
                color: cs.tertiary,
              );
            }
            return _Chip(
              icon: Icons.cloud_done_outlined,
              label: 'Synced',
              color: cs.primary,
            );
          },
        );
      },
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable cloud sync'),
        content: const Text(
          'Create a free account to sync your habits across devices and keep them safe if you switch phones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to AuthScreen in sign-up mode
              Navigator.of(context).pushNamed('/auth');
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
