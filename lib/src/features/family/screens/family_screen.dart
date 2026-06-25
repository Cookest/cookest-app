import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cookest_ui/cookest_ui.dart';
import 'package:cookest/src/core/theme/app_colors.dart';
import '../repositories/household_repository.dart';
import '../../profile/repositories/profile_repository.dart';

/// Family / household screen: create or join a family group, see members, and
/// share an invite code so relatives can join and help plan meals.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  final _nameController = TextEditingController();
  final _joinController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(myHouseholdProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(Household household) async {
    await _run(() async {
      final token =
          await ref.read(householdRepositoryProvider).createInvite(household.id);
      await Clipboard.setData(ClipboardData(text: token));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite code copied — share it with your family'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(myHouseholdProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        title: Text('Family',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold, color: context.appHeading)),
      ),
      body: householdAsync.when(
        loading: () => const Center(child: CkSpinner()),
        error: (e, _) => Center(child: Text('$e')),
        data: (household) => household == null
            ? _buildEmptyState()
            : _buildHousehold(household),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan meals together',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.appHeading)),
          const SizedBox(height: 8),
          Text(
            'Create a family so everyone can help choose what to cook, or join '
            'an existing one with an invite code.',
            style: GoogleFonts.inter(color: context.appMuted, height: 1.4),
          ),
          const SizedBox(height: 24),
          CkInput(
            controller: _nameController,
            label: 'Family name',
            placeholder: 'e.g. The Smiths',
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          CkButton(
            onPressed: _busy
                ? null
                : () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    _run(() async => ref
                        .read(householdRepositoryProvider)
                        .create(name));
                  },
            loading: _busy,
            fullWidth: true,
            child: const Text('Create family'),
          ),
          const SizedBox(height: 32),
          Divider(color: context.appBorder),
          const SizedBox(height: 24),
          Text('Have an invite code?',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: context.appHeading)),
          const SizedBox(height: 12),
          CkInput(
            controller: _joinController,
            label: 'Invite code',
            placeholder: 'Paste the code you received',
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          CkButton(
            variant: CkButtonVariant.secondary,
            onPressed: _busy
                ? null
                : () {
                    final token = _joinController.text.trim();
                    if (token.isEmpty) return;
                    _run(() async =>
                        ref.read(householdRepositoryProvider).join(token));
                  },
            fullWidth: true,
            child: const Text('Join family'),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(HouseholdMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Family'),
        content: Text('Are you sure you want to remove ${member.name ?? 'this member'} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _run(() async {
      await ref.read(householdRepositoryProvider).removeMember(member.userId);
    });
  }

  Future<void> _transferOwnership(HouseholdMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Ownership'),
        content: Text('Are you sure you want to transfer family ownership to ${member.name ?? 'this member'}? You will become a regular member.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _run(() async {
      await ref.read(householdRepositoryProvider).transferOwnership(member.userId);
    });
  }

  Future<void> _leaveFamily(String currentUserId, bool isOwner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: Text(isOwner
            ? 'Are you sure you want to leave the family? Since you are the owner, ownership will be transferred to another member. If you are the last member, the family group will be disbanded.'
            : 'Are you sure you want to leave the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _run(() async {
      await ref.read(householdRepositoryProvider).removeMember(currentUserId);
    });
  }

  Widget _buildHousehold(Household household) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final isOwner = profile != null && household.ownerId == profile.id;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(household.name,
            style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: context.appHeading)),
        const SizedBox(height: 4),
        Text('${household.members.length} member'
            '${household.members.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(color: context.appMuted)),
        const SizedBox(height: 20),
        ...household.members.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      CookestTokens.colorPrimaryDEFAULT.withValues(alpha: 0.15),
                  child: Icon(LucideIcons.user,
                      size: 18, color: CookestTokens.colorPrimaryDEFAULT),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m.name ?? 'Member'}${m.userId == profile?.id ? ' (You)' : ''}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: context.appHeading,
                        ),
                      ),
                      Text(
                        m.role == 'owner' ? 'Owner' : 'Member',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner && m.userId != profile.id)
                  PopupMenuButton<String>(
                    icon: Icon(LucideIcons.moreVertical, size: 18, color: context.appMuted),
                    onSelected: (value) {
                      if (value == 'kick') {
                        _kickMember(m);
                      } else if (value == 'transfer') {
                        _transferOwnership(m);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'transfer',
                        child: Row(
                          children: [
                            Icon(LucideIcons.shieldAlert, size: 16),
                            SizedBox(width: 8),
                            Text('Transfer Ownership'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'kick',
                        child: Row(
                          children: [
                            Icon(LucideIcons.userMinus, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove from Family', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CkButton(
          onPressed: _busy ? null : () => _invite(household),
          loading: _busy,
          fullWidth: true,
          iconLeft:
              const Icon(LucideIcons.userPlus, size: 16, color: Colors.white),
          child: const Text('Invite a family member'),
        ),
        const SizedBox(height: 12),
        CkButton(
          variant: CkButtonVariant.ghost,
          onPressed: _busy || profile == null ? null : () => _leaveFamily(profile.id, isOwner),
          loading: _busy,
          fullWidth: true,
          iconLeft: Icon(LucideIcons.logOut, size: 16, color: context.appMuted),
          child: Text('Leave family', style: TextStyle(color: context.appMuted)),
        ),
      ],
    );
  }
}
