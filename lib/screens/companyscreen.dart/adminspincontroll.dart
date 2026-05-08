import 'package:flutter/material.dart';
import 'package:peereess/provider/spinservice.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin panel — flip the switch to push the spin modal to ALL logged-in users
// in real time via Appwrite Realtime.
// ─────────────────────────────────────────────────────────────────────────────

class SpinAdminPage extends StatelessWidget {
  final String adminId; // pass the logged-in admin's userId
  const SpinAdminPage({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpinService>(
      builder: (context, spin, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 217, 194, 162),
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: Color(0xff9D6E2D),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Spin Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: spin.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF9D6E2D)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── Control card ──────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF9D6E2D,
                                ).withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF5EBD8),
                                    ),
                                    child: const Icon(
                                      Icons.casino_rounded,
                                      color: Color(0xFF9D6E2D),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Spin to Win',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'poppins',
                                            color: Color(0xFF5C3A00),
                                          ),
                                        ),
                                        Text(
                                          'Control visibility for all users',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.brown,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(
                                height: 1,
                                color: Color(0xFFEEE0CC),
                              ),
                              const SizedBox(height: 20),

                              // Toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Enable Spin Wheel',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'poppins',
                                          color: Color(0xFF5C3A00),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        spin.spinEnabled
                                            ? 'Active — users can spin now'
                                            : 'Disabled — no one can spin',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: spin.spinEnabled
                                              ? Colors.green.shade700
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: spin.spinEnabled,
                                    activeColor: const Color(0xFF9D6E2D),
                                    onChanged: spin.isLoading
                                        ? null
                                        : (val) => spin.setSpinEnabled(
                                              value: val,
                                              adminId: adminId,
                                            ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Info banner ───────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8EE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8C98A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Color(0xFF9D6E2D),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  spin.spinEnabled
                                      ? 'The spin wheel is LIVE. All logged-in users will see the spin popup on their home screen right now.'
                                      : 'The spin wheel is OFF. Toggle the switch above to push the spin popup to all logged-in users instantly.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7B4F00),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Error message ─────────────────────────────────
                        if (spin.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    spin.errorMessage!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: spin.clearError,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
