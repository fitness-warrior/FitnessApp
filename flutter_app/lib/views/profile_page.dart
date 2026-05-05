import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/recommendation_storage.dart';
import '../widgets/common/navbar.dart';
import '../widgets/questionnaire/questionnaire_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? fitnessProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    // 1. Load user identity
    final user = await AuthService.getCurrentUser();

    // 2. Local cache first — always available after questionnaire
    final cached = await RecommendationStorage.loadProfile();
    Map<String, dynamic>? fitness;
    if (cached != null) {
      fitness = {
        'goal': cached.goal,
        'experience': cached.experience,
        'location':
            cached.equipment.contains('gym_machines') ? 'Gym' : 'Home',
        'session_length': cached.workoutLengthMinutes,
        'age': cached.age > 0 ? cached.age : null,
        'injuries': cached.injuredAreas,
      };
    }

    // 3. Try enriching with API data (has extra fields like height/weight/diet)
    try {
      final apiFitness = await UserService.getQuestionnaireResponse()
          .timeout(const Duration(seconds: 4));
      if (apiFitness != null && apiFitness.isNotEmpty) {
        fitness = apiFitness; // API is richer — prefer it
      }
    } catch (_) {
      // Keep local cache if API is unavailable
    }

    if (mounted) {
      setState(() {
        currentUser = user;
        fitnessProfile = fitness;
        isLoading = false;
      });
    }
  }

  Future<void> _openEditFitnessProfile() async {
    // Navigate to questionnaire in edit mode; it returns true when saved
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const QuestionnairePage(isOnboarding: false),
      ),
    );

    // Reload fitness data if the user saved changes
    if (updated == true && mounted) {
      _loadData();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F2E),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  String _label(String key) {
    const map = {
      'goal': 'Goal',
      'experience': 'Experience',
      'location': 'Workout Location',
      'days_per_week': 'Days / Week',
      'session_length': 'Session Length',
      'injuries': 'Injuries',
      'diet_preference': 'Diet',
      'allergies': 'Allergies',
      'age': 'Age',
      'height': 'Height',
      'weight': 'Weight',
    };
    return map[key] ?? key;
  }

  String _value(String key, dynamic raw) {
    if (raw == null) return '—';
    if (raw is List) {
      final items = raw.cast<String>().where((s) => s.isNotEmpty).toList();
      return items.isEmpty ? 'None' : items.join(', ');
    }
    final s = raw.toString();
    if (s.isEmpty) return '—';

    if (key == 'goal') return _prettifyGoal(s);
    if (key == 'experience') return _prettifyExperience(s);
    if (key == 'diet_preference') return _prettifyDiet(s);
    if (key == 'session_length') return '$s min';
    if (key == 'days_per_week') return '$s / week';
    if (key == 'height') return '$s cm';
    if (key == 'weight') return '$s kg';
    if (key == 'age') return '$s yrs';
    return s;
  }

  // ── prettifiers ─────────────────────────────────────────────────────────────

  String _prettifyGoal(String raw) {
    const map = {
      'fat_loss': 'Lose Weight',
      'lose weight': 'Lose Weight',
      'strength': 'Build Muscle',
      'build muscle': 'Build Muscle',
      'general_fitness': 'Stay Fit',
      'stay fit': 'Stay Fit',
      'weight_gain': 'Gain Weight',
      'gain weight': 'Gain Weight',
    };
    return map[raw.toLowerCase()] ?? raw;
  }

  String _prettifyExperience(String raw) {
    const map = {
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',
    };
    return map[raw.toLowerCase()] ?? raw;
  }

  String _prettifyDiet(String raw) {
    const map = {
      'veg': 'Vegetarian',
      'non-veg': 'Non-Vegetarian',
      'non_veg': 'Non-Vegetarian',
    };
    return map[raw.toLowerCase()] ?? raw;
  }


  // Keys we want to surface and the order to show them in
  static const _fitnessKeys = [
    'goal',
    'experience',
    'location',
    'days_per_week',
    'session_length',
    'age',
    'height',
    'weight',
    'injuries',
    'diet_preference',
    'allergies',
  ];

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F2E),
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentUser == null
              ? const Center(
                  child: Text(
                    'Failed to load user info',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Avatar card ──────────────────────────────────
                          _AvatarCard(currentUser: currentUser!),
                          const SizedBox(height: 20),

                          // ── Fitness profile card ─────────────────────────
                          _SectionHeader(
                            title: 'Fitness Profile',
                            action: TextButton.icon(
                              onPressed: _openEditFitnessProfile,
                              icon: const Icon(Icons.edit,
                                  size: 16, color: Color(0xFF6C63FF)),
                              label: const Text(
                                'Edit',
                                style: TextStyle(color: Color(0xFF6C63FF)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FitnessCard(
                            fitnessProfile: fitnessProfile,
                            fitnessKeys: _fitnessKeys,
                            labelFn: _label,
                            valueFn: _value,
                            onSetUp: _openEditFitnessProfile,
                          ),
                          const SizedBox(height: 24),

                          // ── Account section ──────────────────────────────
                          const _SectionHeader(title: 'Account'),
                          const SizedBox(height: 10),
                          _buildActionButton(
                            icon: Icons.settings,
                            label: 'Settings',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Settings coming soon')),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Logout ───────────────────────────────────────
                          ElevatedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Log Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  final Map<String, dynamic> currentUser;
  const _AvatarCard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              (currentUser['username'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentUser['username'] ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentUser['email'] ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _FitnessCard extends StatelessWidget {
  final Map<String, dynamic>? fitnessProfile;
  final List<String> fitnessKeys;
  final String Function(String) labelFn;
  final String Function(String, dynamic) valueFn;
  final VoidCallback onSetUp;

  const _FitnessCard({
    required this.fitnessProfile,
    required this.fitnessKeys,
    required this.labelFn,
    required this.valueFn,
    required this.onSetUp,
  });

  @override
  Widget build(BuildContext context) {
    if (fitnessProfile == null) {
      // No profile yet — prompt user to fill in the questionnaire
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6C63FF).withAlpha(100),
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.fitness_center, color: Colors.grey, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No fitness profile yet',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Set up your profile so we can personalise your workouts.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onSetUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Set Up Now'),
            ),
          ],
        ),
      );
    }

    // Show fitness data rows
    final rows = fitnessKeys
        .where((k) => fitnessProfile!.containsKey(k))
        .map((k) => _FitnessRow(
              label: labelFn(k),
              value: valueFn(k, fitnessProfile![k]),
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(color: Color(0xFF2A2A3D), height: 1),
          ],
        ],
      ),
    );
  }
}

class _FitnessRow extends StatelessWidget {
  final String label;
  final String value;
  const _FitnessRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
