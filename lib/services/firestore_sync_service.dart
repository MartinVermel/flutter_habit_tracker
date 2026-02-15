import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

/// Syncs local Hive data to Firestore under the authenticated user's uid.
///
/// Data model (Firestore):
///   users/{uid}/habits/{habitId}        — Habit documents
///   users/{uid}/completions/{key}       — HabitCompletion documents
///
/// Design decisions:
/// - Hive is always the source of truth for reads. Firestore is write-through.
/// - On first sign-in, [uploadAll] pushes the full local state to Firestore.
/// - On subsequent sign-ins, [downloadAll] pulls Firestore into Hive so the
///   user's data is available on a new device.
/// - Writes are fire-and-forget (unawaited in hot paths) so the UI never blocks.
class FirestoreSyncService {
  static final FirestoreSyncService _instance =
      FirestoreSyncService._internal();
  factory FirestoreSyncService() => _instance;
  FirestoreSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get isAvailable => _uid != null;

  // ── Collection references ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      _db.collection('users').doc(_uid).collection('habits');

  CollectionReference<Map<String, dynamic>> get _completionsRef =>
      _db.collection('users').doc(_uid).collection('completions');

  // ── Write operations ──────────────────────────────────────────────────────

  /// Upserts a single habit. Called whenever a habit is created or updated.
  Future<void> upsertHabit(Habit habit) async {
    if (!isAvailable) return;
    await _habitsRef.doc(habit.id).set(_habitToMap(habit));
  }

  /// Removes a habit and all its completions in a single batch write.
  /// Batches are atomic — either everything is deleted or nothing is.
  Future<void> deleteHabit(String habitId) async {
    if (!isAvailable) return;

    final batch = _db.batch();

    // Delete the habit document
    batch.delete(_habitsRef.doc(habitId));

    // Delete all completions for this habit
    final completions = await _completionsRef
        .where('habitId', isEqualTo: habitId)
        .get();
    for (final doc in completions.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Upserts a single completion.
  Future<void> upsertCompletion(HabitCompletion completion, String key) async {
    if (!isAvailable) return;
    await _completionsRef.doc(key).set(_completionToMap(completion));
  }

  /// Removes a completion document.
  Future<void> deleteCompletion(String key) async {
    if (!isAvailable) return;
    await _completionsRef.doc(key).delete();
  }

  // ── Bulk operations ───────────────────────────────────────────────────────

  /// Pushes the full local state to Firestore.
  /// Called once after a user creates a new account to seed their cloud data.
  /// Uses batched writes (max 500 ops per batch) to avoid per-write costs.
  Future<void> uploadAll({
    required List<Habit> habits,
    required List<MapEntry<String, HabitCompletion>> completions,
  }) async {
    if (!isAvailable) return;

    final allOps = <Map<String, dynamic>>[];

    for (final h in habits) {
      allOps.add({'ref': _habitsRef.doc(h.id), 'data': _habitToMap(h)});
    }
    for (final entry in completions) {
      allOps.add({
        'ref': _completionsRef.doc(entry.key),
        'data': _completionToMap(entry.value),
      });
    }

    // Firestore batches are capped at 500 operations
    for (int i = 0; i < allOps.length; i += 500) {
      final batch = _db.batch();
      final chunk = allOps.skip(i).take(500);
      for (final op in chunk) {
        batch.set(
            op['ref'] as DocumentReference<Map<String, dynamic>>, op['data']);
      }
      await batch.commit();
    }
  }

  /// Pulls all habits and completions from Firestore and returns them.
  /// Called when a user signs into an existing account on a new device.
  Future<SyncResult> downloadAll() async {
    if (!isAvailable) return const SyncResult(habits: [], completions: []);

    final habitSnap = await _habitsRef.get();
    final completionSnap = await _completionsRef.get();

    final habits = habitSnap.docs.map((d) => _habitFromMap(d.id, d.data())).toList();
    final completions = completionSnap.docs
        .map((d) => MapEntry(d.id, _completionFromMap(d.data())))
        .toList();

    return SyncResult(habits: habits, completions: completions);
  }

  // ── Real-time listener ────────────────────────────────────────────────────

  /// Returns a stream of habit documents for the current user.
  /// Useful for a multi-device sync indicator in the UI.
  Stream<QuerySnapshot<Map<String, dynamic>>> habitsStream() {
    if (!isAvailable) return const Stream.empty();
    return _habitsRef.snapshots();
  }

  // ── Serialisation helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _habitToMap(Habit h) => {
        'id': h.id,
        'name': h.name,
        'emoji': h.emoji,
        'colorValue': h.colorValue,
        'frequency': h.frequency.index,
        'createdAt': Timestamp.fromDate(h.createdAt),
        'isArchived': h.isArchived,
      };

  Habit _habitFromMap(String id, Map<String, dynamic> map) => Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        colorValue: map['colorValue'] as int,
        frequency: Frequency.values[map['frequency'] as int],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      )..isArchived = map['isArchived'] as bool? ?? false;

  Map<String, dynamic> _completionToMap(HabitCompletion c) => {
        'habitId': c.habitId,
        'date': Timestamp.fromDate(c.date),
        'completedAt': Timestamp.fromDate(c.completedAt),
      };

  HabitCompletion _completionFromMap(Map<String, dynamic> map) =>
      HabitCompletion(
        habitId: map['habitId'] as String,
        date: (map['date'] as Timestamp).toDate(),
        completedAt: (map['completedAt'] as Timestamp).toDate(),
      );
}

/// Result of a [FirestoreSyncService.downloadAll] call.
class SyncResult {
  final List<Habit> habits;
  final List<MapEntry<String, HabitCompletion>> completions;
  const SyncResult({required this.habits, required this.completions});
}
