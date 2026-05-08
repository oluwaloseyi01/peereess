import 'package:flutter/material.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';

import 'package:peereess/provider/withdrawservice.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId ?? '';
      context.read<WithdrawService>().fetchWithdrawalsForUser(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 217, 194, 162),
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
            10.getWidthWhiteSpacing,
            const Text(
              "Withdrawal History",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: "poppins",
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
        child: Consumer<WithdrawService>(
          builder: (context, service, _) {
            if (service.isLoading && service.withdrawRows.isEmpty) {
              return const Center(child: LogoLoadingIndicator());
            }

            if (service.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        service.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final userId =
                              context.read<AuthProvider>().userId ?? '';
                          service.fetchWithdrawalsForUser(userId: userId);
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (service.withdrawRows.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No withdrawal history",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your withdrawal requests will appear here",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final userId = context.read<AuthProvider>().userId ?? '';
                await service.fetchWithdrawalsForUser(userId: userId);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: service.withdrawRows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final withdrawal = service.withdrawRows[index];
                  final String bankName = withdrawal['bankName'] ?? '—';
                  final String accountName = withdrawal['accountName'] ?? '—';
                  final String accountNumber =
                      withdrawal['accountNumber'] ?? '—';
                  final String amount = withdrawal['amount']?.toString() ?? '0';
                  final String status = (withdrawal['status'] ?? 'pending')
                      .toString()
                      .toLowerCase();
                  final String createdAt = withdrawal['\$createdAt'] ?? '';

                  // Format date
                  String formattedDate = '—';
                  if (createdAt.isNotEmpty) {
                    try {
                      final date = DateTime.parse(createdAt);
                      formattedDate = DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(date);
                    } catch (_) {}
                  }

                  // Status color
                  Color statusColor;
                  IconData statusIcon;
                  switch (status) {
                    case 'approved':
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      break;
                    case 'rejected':
                      statusColor = Colors.red;
                      statusIcon = Icons.cancel;
                      break;
                    default:
                      statusColor = Colors.orange;
                      statusIcon = Icons.pending;
                  }

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Amount + Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Amount",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₦${NumberFormat('#,##0').format(double.tryParse(amount) ?? 0)}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Bank Details
                          const Text(
                            "Bank Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildInfoRow(
                            Icons.account_balance,
                            "Bank Name",
                            bankName,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.person_outline,
                            "Account Name",
                            accountName,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.numbers,
                            "Account Number",
                            accountNumber,
                          ),

                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Date
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
