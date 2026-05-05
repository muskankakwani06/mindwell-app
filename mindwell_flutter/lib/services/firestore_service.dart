import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  // --- Dashboard Data ---
  Future<Map<String, dynamic>> getDashboardData() async {
    if (userId.isEmpty) return {};

    try {
      // Fetch stats
      final appointments = await _db.collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();
      
      final assessments = await _db.collection('assessments')
          .where('userId', isEqualTo: userId)
          .get();

      final groups = await _db.collection('groups')
          .where('members', arrayContains: userId)
          .get();

      final payments = await _db.collection('payments')
          .where('userId', isEqualTo: userId)
          .get();

      final upcoming = appointments.docs.where((doc) {
        final date = DateTime.tryParse(doc.data()['date'] ?? '');
        return date != null && date.isAfter(DateTime.now());
      }).length;

      final completed = appointments.docs.where((doc) => doc.data()['status'] == 'completed').length;

      return {
        'stats': {
          'sessions': completed,
          'assessments': assessments.size,
          'groups': groups.size,
          'upcoming': upcoming,
          'payments': payments.size,
        },
        'recentAssessments': assessments.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList(),
        'upcomingAppointments': appointments.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .where((a) {
              final date = DateTime.tryParse(a['date'] ?? '');
              return date != null && date.isAfter(DateTime.now());
            })
            .toList(),
        'recentPayments': payments.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList(),
      };
    } catch (e) {
      print('Error fetching dashboard data: $e');
      return {};
    }
  }

  // --- Auth Profile ---
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (userId.isEmpty) return null;
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }
}
