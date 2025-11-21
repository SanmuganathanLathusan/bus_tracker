import 'package:flutter/material.dart';

class TicketPurchasePage extends StatefulWidget {
  final String userId;

  // Constructor rewritten (same behavior, slightly different formatting)
  const TicketPurchasePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

// Enum reformatted (no behavior change)
enum PaymentMethod {
  Card,
  Bank,
  MobileWallet,
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  // Colors written using Flutter const syntax alternative
  static const Color primaryColor = Color.fromARGB(255, 12, 56, 102);
  static const Color accentColor = Color.fromARGB(255, 255, 160, 0);

  // Reformatted with clearer naming (still same variable)
  int currentStepIndex = 0; // Previously _currentStep
}


  // Traveller Details
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();

  // Booking Details
  final TextEditingController _routeController = TextEditingController(text: 'Colombo to Jaffna');
  final TextEditingController _busIdController = TextEditingController(text: 'KCB7-2000-C/2');
  final TextEditingController _seatController = TextEditingController(text: '1');
  final double farePerSeat = 1385.40;
  double totalPrice = 1385.40;

  // Payment
  PaymentMethod _paymentMethod = PaymentMethod.Card;
  String? _cardType = 'Visa';
  String? _selectedMonth = '01';
  String? _selectedYear = DateTime.now().year.toString();
  String? _selectedBank;
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  final List<String> _months = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  final List<String> _years = List.generate(10, (i) => (DateTime.now().year + i).toString());

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _nicController.dispose();
    _routeController.dispose();
    _busIdController.dispose();
    _seatController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Validation
  bool _validateTraveller() {
    final mobileRegex = RegExp(r'^07\d{8}$');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    final nicRegex = RegExp(r'^(\d{9}[VvXx]|\d{12})$');

    if (_nameController.text.isEmpty ||
        !mobileRegex.hasMatch(_mobileController.text) ||
        !emailRegex.hasMatch(_emailController.text) ||
        (_nicController.text.isNotEmpty && !nicRegex.hasMatch(_nicController.text))) {
      return false;
    }
    return true;
  }

  bool _validatePayment() {
    if (_paymentMethod == PaymentMethod.Card) {
      return _cardHolderController.text.isNotEmpty &&
          _cardNumberController.text.length == 16 &&
          _cvvController.text.length >= 3;
    }
    if (_paymentMethod == PaymentMethod.Bank) return _selectedBank != null;
    if (_paymentMethod == PaymentMethod.MobileWallet) return _mobileController.text.isNotEmpty;
    return false;
  }

  void _updateTotalPrice() {
    int seats = int.tryParse(_seatController.text) ?? 1;
    setState(() {
      totalPrice = seats * farePerSeat;
    });
  }

  Future<void> _processPayment() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: accentColor)),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of Rs. ${totalPrice.toStringAsFixed(2)} successful!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Stepper Steps
  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Traveller'),
        content: Column(
          children: [
            _buildTextField(_nameController, 'Full Name *', TextInputType.name),
            _buildTextField(_mobileController, 'Mobile No. *', TextInputType.phone),
            _buildTextField(_emailController, 'Email *', TextInputType.emailAddress),
            _buildTextField(_nicController, 'NIC / Passport No.', TextInputType.text),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Booking'),
        content: Column(
          children: [
            _buildReadOnlyField(_routeController, 'Bus Route'),
            _buildReadOnlyField(_busIdController, 'Bus ID'),
            _buildTextField(_seatController, 'Seat(s)', TextInputType.number, onChanged: (_) => _updateTotalPrice()),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Total Price: Rs. ${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
            ),
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Payment'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Payment Method *', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 10,
              children: [
                _buildPaymentMethodRadio(PaymentMethod.Card, 'Card'),
                _buildPaymentMethodRadio(PaymentMethod.Bank, 'Bank'),
                _buildPaymentMethodRadio(PaymentMethod.MobileWallet, 'Wallet'),
              ],
            ),
            const SizedBox(height: 10),
            if (_paymentMethod == PaymentMethod.Card) _buildCardPaymentFields(),
            if (_paymentMethod == PaymentMethod.Bank) _buildBankDropdown(['BOC', 'HNB', 'Sampath']),
            if (_paymentMethod == PaymentMethod.MobileWallet)
              _buildTextField(_mobileController, 'Wallet Phone Number *', TextInputType.phone),
          ],
        ),
        isActive: _currentStep >= 2,
        state: StepState.indexed,
      ),
    ];
  }

  // Widget Helpers
  Widget _buildTextField(TextEditingController controller, String label, TextInputType type,
      {Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          fillColor: Colors.grey.shade200,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRadio(PaymentMethod method, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<PaymentMethod>(
          value: method,
          groupValue: _paymentMethod,
          onChanged: (val) => setState(() => _paymentMethod = val!),
          activeColor: primaryColor,
        ),
        Text(label),
      ],
    );
  }

  Widget _buildCardPaymentFields() {
    return Column(
      children: [
        _buildDropdown('Card Type', ['Visa', 'Mastercard', 'Amex'], _cardType, (v) => setState(() => _cardType = v)),
        _buildTextField(_cardHolderController, 'Card Holder Name *', TextInputType.text),
        _buildTextField(_cardNumberController, 'Card Number *', TextInputType.number),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Month', _months, _selectedMonth, (v) => setState(() => _selectedMonth = v)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDropdown('Year', _years, _selectedYear, (v) => setState(() => _selectedYear = v)),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(_cvvController, 'CVV', TextInputType.number)),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBankDropdown(List<String> banks) {
    _selectedBank ??= banks.first;
    return _buildDropdown('Select Bank', banks, _selectedBank, (v) => setState(() => _selectedBank = v));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bus Ticket Purchase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Stepper(
          type: StepperType.vertical,
          physics: const ClampingScrollPhysics(),
          currentStep: _currentStep,
          steps: _buildSteps(),
          onStepContinue: () async {
            if (_currentStep == 0 && !_validateTraveller()) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Please enter valid traveller details.')));
              return;
            } else if (_currentStep == 1) {
              _updateTotalPrice();
            } else if (_currentStep == 2) {
              if (!_validatePayment()) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Please enter valid payment info.')));
                return;
              }
              await _processPayment();
              return;
            }
            if (_currentStep < 2) setState(() => _currentStep += 1);
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: primaryColor,
                    ),
                    child: Text(_currentStep == 2 ? 'Pay Now' : 'Next'),
                  ),
                  const SizedBox(width: 10),
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
