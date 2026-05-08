import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:peereess/provider/auth_provider.dart';
// ✅ added
import 'package:peereess/provider/ledgerprovider.dart';
import 'package:peereess/provider/withdrawservice.dart';
import 'package:peereess/screens/widgets/loadingwidget.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final PageController _pageController = PageController();
  final WithdrawService _service = WithdrawService();
  final formatter = NumberFormat('#,##0', 'en_US');

  String _userId = '';
  String _rowId = '';

  bool _hasPin = false;
  bool _isCheckingPin = true;
  String _verifiedPin = '';
  bool _withdrawSuccess = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  String _confirmedPin = '';

  // ✅ Use LedgerProvider.getBalance instead of calculateTotalRevenue
  double _calculateAvailableBalance() {
    final userId = context.read<AuthProvider>().userId ?? '';
    return context.read<LedgerProvider>().getBalance(userId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      _userId = auth.userId ?? '';
      _rowId = auth.rowId ?? '';

      // ✅ Ensure ledger is fetched for this user
      if (_userId.isNotEmpty) {
        await context.read<LedgerProvider>().fetchLedger(userId: _userId);
      }

      final has = await _service.hasPin(userId: _userId);
      if (mounted) {
        setState(() {
          _hasPin = has;
          _isCheckingPin = false;
        });
      }
    });
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPinSuccess(String rawPin) {
    setState(() => _verifiedPin = rawPin);
    _goToPage(1);
  }

  Future<void> _onSubmitWithdrawal() async {
    if (_amountController.text.trim().isEmpty ||
        _bankNameController.text.trim().isEmpty ||
        _accountNameController.text.trim().isEmpty ||
        _accountNumberController.text.trim().isEmpty ||
        _confirmedPin.length != 4) {
      _showSnack('Please fill all fields and enter your PIN', isError: true);
      return;
    }

    final isMatch = await _service.verifyPin(
      userId: _userId,
      enteredRawPin: _confirmedPin,
    );

    if (!mounted) return;

    if (!isMatch) {
      _showSnack(
        _service.errorMessage ?? 'PIN does not match. Please try again.',
        isError: true,
      );
      setState(() => _confirmedPin = '');
      return;
    }

    final success = await _service.submitWithdrawal(
      userId: _userId,
      bankName: _bankNameController.text.trim(),
      accountName: _accountNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      amount: _amountController.text.trim(),
      totalRevenue: _calculateAvailableBalance(),
    );

    if (!mounted) return;
    setState(() => _withdrawSuccess = success);
    _goToPage(2);
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _verifiedPin = '';
      _confirmedPin = '';
      _amountController.clear();
      _bankNameController.clear();
      _accountNameController.clear();
      _accountNumberController.clear();
    });
    _goToPage(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xff9D6E2D),
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 217, 194, 162),
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
        child: _isCheckingPin
            ? const Center(child: LogoLoadingIndicator())
            : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ── Page 1: PIN ────────────────────────────────────────────
                  _PinPage(
                    hasPin: _hasPin,
                    userId: _userId,
                    rowId: _rowId,
                    service: _service,
                    onPinSuccess: _onPinSuccess,
                  ),

                  // ── Page 2: Form ───────────────────────────────────────────
                  _WithdrawalFormPage(
                    totalRevenue: _calculateAvailableBalance(),
                    formatter: formatter,
                    amountController: _amountController,
                    bankNameController: _bankNameController,
                    accountNameController: _accountNameController,
                    accountNumberController: _accountNumberController,
                    service: _service,
                    confirmedPin: _confirmedPin,
                    onConfirmPinChanged: (pin) =>
                        setState(() => _confirmedPin = pin),
                    onSubmit: _onSubmitWithdrawal,
                  ),

                  // ── Page 3: Result ─────────────────────────────────────────
                  _ResultPage(
                    isSuccess: _withdrawSuccess,
                    amount: _amountController.text,
                    formatter: formatter,
                    onDone: () => Navigator.pop(context),
                    onRetry: _resetAll,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1 — PIN setup or entry
// ─────────────────────────────────────────────────────────────────────────────

class _PinPage extends StatefulWidget {
  final bool hasPin;
  final String userId;
  final String rowId;
  final WithdrawService service;
  final ValueChanged<String> onPinSuccess;

  const _PinPage({
    required this.hasPin,
    required this.userId,
    required this.rowId,
    required this.service,
    required this.onPinSuccess,
  });

  @override
  State<_PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<_PinPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isConfirming = false;
  String _firstPin = '';
  String? _error;
  bool _isProcessing = false;

  String get _pin => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    setState(() => _error = null);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _handlePinComplete);
    }
  }

  Future<void> _handlePinComplete() async {
    if (_isProcessing) return;
    final pin = _pin;
    setState(() => _isProcessing = true);

    if (widget.hasPin) {
      final isValid = await widget.service.verifyPin(
        userId: widget.userId,
        enteredRawPin: pin,
      );
      if (!mounted) return;
      if (isValid) {
        widget.onPinSuccess(pin);
      } else {
        setState(() {
          _error = widget.service.errorMessage ?? 'Incorrect PIN. Try again.';
          _isProcessing = false;
        });
        _clearFields();
      }
    } else {
      if (!_isConfirming) {
        setState(() {
          _firstPin = pin;
          _isConfirming = true;
          _isProcessing = false;
        });
        _clearFields();
      } else {
        if (pin == _firstPin) {
          final saved = await widget.service.createPin(
            userId: widget.userId,
            rowId: widget.rowId,
            rawPin: pin,
          );
          if (!mounted) return;
          if (saved) {
            widget.onPinSuccess(pin);
          } else {
            setState(() {
              _error = widget.service.errorMessage ?? 'Failed to save PIN.';
              _isConfirming = false;
              _firstPin = '';
              _isProcessing = false;
            });
            _clearFields();
          }
        } else {
          setState(() {
            _error = 'PINs do not match. Please try again.';
            _isConfirming = false;
            _firstPin = '';
            _isProcessing = false;
          });
          _clearFields();
        }
      }
    }
  }

  void _clearFields() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = !widget.hasPin;
    final title = isCreating
        ? (_isConfirming ? 'Confirm your PIN' : 'Create a PIN')
        : 'Enter your PIN';
    final subtitle = isCreating
        ? (_isConfirming
            ? 'Re-enter your 4-digit PIN to confirm'
            : 'Set a 4-digit PIN to secure your withdrawals')
        : 'Enter your 4-digit withdrawal PIN';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xffB0864C).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xffB0864C),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // PIN boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Container(
                      width: 58,
                      height: 58,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _focusNodes[i].hasFocus
                              ? const Color(0xffB0864C)
                              : const Color(0xffE0D5C8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffB0864C),
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                if (_isProcessing)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: LogoLoadingIndicator(),
                  ),

                if (_error != null && !_isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isCreating) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepDot(active: !_isConfirming),
                      const SizedBox(width: 8),
                      _StepDot(active: _isConfirming),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xffB0864C) : const Color(0xffE0D5C8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2 — Withdrawal form
// ─────────────────────────────────────────────────────────────────────────────

class _WithdrawalFormPage extends StatefulWidget {
  final double totalRevenue;
  final NumberFormat formatter;
  final TextEditingController amountController;
  final TextEditingController bankNameController;
  final TextEditingController accountNameController;
  final TextEditingController accountNumberController;
  final WithdrawService service;
  final String confirmedPin;
  final ValueChanged<String> onConfirmPinChanged;
  final VoidCallback onSubmit;

  const _WithdrawalFormPage({
    required this.totalRevenue,
    required this.formatter,
    required this.amountController,
    required this.bankNameController,
    required this.accountNameController,
    required this.accountNumberController,
    required this.service,
    required this.confirmedPin,
    required this.onConfirmPinChanged,
    required this.onSubmit,
  });

  @override
  State<_WithdrawalFormPage> createState() => _WithdrawalFormPageState();
}

class _WithdrawalFormPageState extends State<_WithdrawalFormPage> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  void _onPinDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) _pinFocusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _pinFocusNodes[index - 1].requestFocus();
    final pin = _pinControllers.map((c) => c.text).join();
    widget.onConfirmPinChanged(pin);
  }

  @override
  void dispose() {
    for (final c in _pinControllers) c.dispose();
    for (final f in _pinFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final isLoading = widget.service.isLoading;

        // ✅ Use LedgerProvider for live balance updates
        final userId = context.watch<AuthProvider>().userId ?? '';
        final ledgerProvider = context.watch<LedgerProvider>();
        final totalRevenue = ledgerProvider.getBalance(userId);

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Balance card ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 3, 59, 6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₦${widget.formatter.format(totalRevenue)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Withdrawal details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in the details below to complete your withdrawal',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  _FormLabel(label: 'Amount (₦)'),
                  const SizedBox(height: 8),
                  _FormField(
                    controller: widget.amountController,
                    hint: 'Enter amount',
                    keyboardType: TextInputType.number,
                    prefix: const Text(
                      '₦',
                      style: TextStyle(
                        color: Color(0xffB0864C),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 16),
                  _FormLabel(label: 'Bank name'),
                  const SizedBox(height: 8),
                  _FormField(
                    controller: widget.bankNameController,
                    hint: 'e.g. First Bank, GTBank',
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 16),
                  _FormLabel(label: 'Account name'),
                  const SizedBox(height: 8),
                  _FormField(
                    controller: widget.accountNameController,
                    hint: 'Your full account name',
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 16),
                  _FormLabel(label: 'Account number'),
                  const SizedBox(height: 8),
                  _FormField(
                    controller: widget.accountNumberController,
                    hint: 'Your 10-digit account number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Container(height: 1, color: const Color(0xffE8DDD0)),
                  const SizedBox(height: 20),

                  const Text(
                    'Confirm PIN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Re-enter your withdrawal PIN to confirm',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      return Container(
                        width: 52,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _pinFocusNodes[i].hasFocus
                                ? const Color(0xffB0864C)
                                : const Color(0xffE0D5C8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _pinControllers[i],
                          focusNode: _pinFocusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffB0864C),
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (v) => _onPinDigitChanged(i, v),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : widget.onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffB0864C),
                        disabledBackgroundColor: const Color(
                          0xffB0864C,
                        ).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: LogoLoadingIndicator(),
                            )
                          : const Text(
                              'Withdraw',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 3 — Result
// ─────────────────────────────────────────────────────────────────────────────

class _ResultPage extends StatelessWidget {
  final bool isSuccess;
  final String amount;
  final NumberFormat formatter;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  const _ResultPage({
    required this.isSuccess,
    required this.amount,
    required this.formatter,
    required this.onDone,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final double parsedAmount = double.tryParse(amount) ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 217, 194, 162), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xff2E7D32).withOpacity(0.1)
                          : Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      color: isSuccess
                          ? const Color(0xff2E7D32)
                          : Colors.red.shade400,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    isSuccess ? 'Withdrawal successful!' : 'Withdrawal failed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isSuccess
                          ? const Color(0xff2E7D32)
                          : Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSuccess
                        ? 'Your withdrawal of ₦${formatter.format(parsedAmount)} has been submitted and is being processed.'
                        : 'Something went wrong with your withdrawal. Please try again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSuccess ? onDone : onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffB0864C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSuccess ? 'Done' : 'Try again',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (isSuccess) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text(
                        'Make another withdrawal',
                        style:
                            TextStyle(color: Color(0xffB0864C), fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.prefix,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE0D5C8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: prefix,
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
