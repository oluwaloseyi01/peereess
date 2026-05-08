import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:peereess/provider/withdrawservice.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatter = NumberFormat("#,##0", "en_US");

  static const _gradientTop = Color.fromARGB(255, 217, 194, 162);
  static const _brown = Color(0xff9D6E2D);
  static const _brownDeep = Color(0xFF6B4A1B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      context.read<WithdrawService>().fetchWithdrawalsWithUserInfo(
            userId: auth.userId!,
          );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade400;
      default:
        return Colors.orange.shade700;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.green.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return Colors.orange.shade50;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> all) {
    switch (_tabController.index) {
      case 1:
        return all.where((w) => w['status'] == 'pending').toList();
      case 2:
        return all
            .where(
              (w) => w['status'] == 'approved' || w['status'] == 'rejected',
            )
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientTop, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<WithdrawService>(
          builder: (context, service, _) {
            if (service.isLoading) {
              return const Center(child: LogoLoadingIndicator());
            }

            final all = service.withdrawRows;
            final filtered = _filtered(all);

            return Column(
              children: [
                _buildStatsRow(all),
                _buildTabBar(),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _buildWithdrawCard(filtered[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientTop, Color(0xFFF0E2CE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: _brown,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Withdrawal Requests",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _brownDeep,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: _brown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────
  Widget _buildStatsRow(List<Map<String, dynamic>> all) {
    final pending = all.where((w) => w['status'] == 'pending').length;
    final approved = all.where((w) => w['status'] == 'approved').length;
    final total = all.fold<double>(
      0,
      (s, w) => s + (double.tryParse(w['amount']?.toString() ?? '0') ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          _StatChip(
            label: "Total",
            value: "${all.length}",
            color: _brown,
            icon: Icons.list_alt_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: "Pending",
            value: "$pending",
            color: Colors.orange.shade600,
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: "Approved",
            value: "$approved",
            color: Colors.green.shade600,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: "Volume",
            value: "₦${formatter.format(total)}",
            color: _brownDeep,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade100),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _brown,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.brown.shade400,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Pending"),
            Tab(text: "Resolved"),
          ],
        ),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────
  Widget _buildWithdrawCard(Map<String, dynamic> w) {
    final status = (w['status'] ?? 'pending').toString();
    final amount = double.tryParse(w['amount']?.toString() ?? '0') ?? 0;
    final createdAt = w['createdAt'] != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(
            DateTime.tryParse(w['createdAt'].toString()) ?? DateTime.now(),
          )
        : '—';
    final isPending = status.toLowerCase() == 'pending';

    // ── Enriched user fields ──────────────────────────────
    final sellerName = (w['sellerName'] ?? '—').toString();
    final sellerPhone = (w['sellerPhone'] ?? '—').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? Colors.orange.shade200 : Colors.brown.shade100,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount + status ───────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_gradientTop, _brown],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "₦${formatter.format(amount)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 13,
                        color: _statusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Seller info banner ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _gradientTop.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _gradientTop.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_gradientTop, _brown],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sellerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _brownDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: Colors.brown.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sellerPhone,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.brown.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.brown.shade100),
            const SizedBox(height: 8),

            // ── Bank details ──────────────────────────────
            _InfoRow(
              icon: Icons.account_balance_outlined,
              label: "Bank",
              value: w['bankName']?.toString() ?? '—',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: "Account Name",
              value: w['accountName']?.toString() ?? '—',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.tag_rounded,
              label: "Account No.",
              value: w['accountNumber']?.toString() ?? '—',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: "Requested",
              value: createdAt,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.fingerprint_rounded,
              label: "Withdraw ID",
              value: w['withdrawId']?.toString() ?? '—',
              small: true,
            ),

            // ── Actions ───────────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.brown.shade100),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: "Approve",
                      icon: Icons.check_rounded,
                      color: Colors.green.shade600,
                      bgColor: Colors.green.shade50,
                      borderColor: Colors.green.shade200,
                      onTap: () => _confirmAction(context, w, 'approved'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      label: "Reject",
                      icon: Icons.close_rounded,
                      color: Colors.red.shade400,
                      bgColor: Colors.red.shade50,
                      borderColor: Colors.red.shade200,
                      onTap: () => _confirmAction(context, w, 'rejected'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Confirm dialog ─────────────────────────────────────────
  void _confirmAction(
    BuildContext context,
    Map<String, dynamic> w,
    String action,
  ) {
    final amount = double.tryParse(w['amount']?.toString() ?? '0') ?? 0;
    final isApprove = action == 'approved';
    final sellerName = (w['sellerName'] ?? 'this seller').toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isApprove
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: isApprove ? Colors.green.shade600 : Colors.red.shade400,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isApprove ? "Approve Withdrawal" : "Reject Withdrawal",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _brownDeep,
                ),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.brown.shade600,
              height: 1.5,
            ),
            children: [
              TextSpan(text: isApprove ? "Approve " : "Reject "),
              TextSpan(
                text: "₦${formatter.format(amount)} ",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _brown,
                ),
              ),
              TextSpan(
                text:
                    isApprove ? "withdrawal for " : "withdrawal request from ",
              ),
              TextSpan(
                text: sellerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _brownDeep,
                ),
              ),
              const TextSpan(text: "?"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              final auth = context.read<AuthProvider>();
              if (auth.userId == null) return;

              final success =
                  await context.read<WithdrawService>().updateWithdrawalStatus(
                        adminId: auth.userId!,
                        withdrawId: w['withdrawId'].toString(),
                        status: action,
                      );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          success
                              ? (isApprove
                                  ? "Withdrawal approved!"
                                  : "Withdrawal rejected.")
                              : "Action failed. Try again.",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? (isApprove
                            ? Colors.green.shade600
                            : Colors.red.shade400)
                        : Colors.grey.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(12),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isApprove ? Colors.green.shade600 : Colors.red.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isApprove ? "Approve" : "Reject",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.7),
              border: Border.all(color: Colors.brown.shade100),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: _brown,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No withdrawals found",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _brownDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No requests in this category yet",
            style: TextStyle(fontSize: 12.5, color: Colors.brown.shade400),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9.5, color: Colors.brown.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool small;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xff9D6E2D).withOpacity(0.7)),
        const SizedBox(width: 7),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.brown.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: small ? 10.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C1A0E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
