import 'package:flutter/material.dart';

class TicketPurchasePage extends StatefulWidget {
  final String userId;

  const TicketPurchasePage({super.key, required this.userId});

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  // Constants for styling
  static const Color primaryColor = Color(0xFF0C3866); // Dark Navy Blue
  static const Color accentColor = Color(0xFFFFA000); // Amber/Orange for Action

  // Payment and UI State
  String? _cardType = 'Visa';
  String? _selectedMonth = '01';
  String? _selectedYear = '2025';

  // Input Controllers for Booking Details (now editable inputs)
  final TextEditingController _routeController = TextEditingController(text: 'Colombo to Jaffna');
  final TextEditingController _busIdController = TextEditingController(text: 'KCB7-2000-C/2');
  final TextEditingController _seatController = TextEditingController(text: '40'); 
  final TextEditingController _priceController = TextEditingController(text: '1385.40');
  
  // Traveller Details Controllers
  final TextEditingController _nameController = TextEditingController(text: 'John A. Doe');
  final TextEditingController _mobileController = TextEditingController(text: '701234567');
  final TextEditingController _emailController = TextEditingController(text: 'name@example.lk');
  final TextEditingController _nicController = TextEditingController(text: '012345678V');

  final List<String> _months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  final List<String> _years = List<String>.generate(10, (i) => (DateTime.now().year + i).toString());

  @override
  void dispose() {
    _routeController.dispose();
    _busIdController.dispose();
    _seatController.dispose();
    _priceController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  // --- Section 1: Traveller Information ---

  Widget _buildTravellerDetailsSection() {
    return _buildSectionCard(
      title: '1. Traveller Information',
      icon: Icons.person,
      children: [
        // Traveller Form fields
        Wrap(
          spacing: 20.0,
          runSpacing: 20.0,
          children: [
            _buildDetailField(label: 'Full Name', hint: 'John A. Doe', controller: _nameController, isRequired: true),
            _buildDetailField(label: 'Mobile No.', hint: '701234567', controller: _mobileController, isRequired: true, keyboardType: TextInputType.phone),
            _buildDetailField(label: 'eMail', hint: 'name@example.lk', controller: _emailController, isRequired: true, keyboardType: TextInputType.emailAddress),
            _buildDetailField(label: 'NIC/Passport No.', hint: '012345678V', controller: _nicController, isRequired: false),
          ],
        ),
      ],
    );
  }

  // --- Section 2: Booking Details (Inputs) ---

  Widget _buildBookingDetailsSection() {
    return _buildSectionCard(
      title: '2. Booking Details',
      icon: Icons.directions_bus, 
      children: [
        // Booking Input Fields
        Wrap(
          spacing: 20.0,
          runSpacing: 20.0,
          children: [
            _buildDetailField(label: 'Bus Route', hint: 'E.g., Colombo to Jaffna', controller: _routeController, isRequired: true),
            _buildDetailField(label: 'Bus ID/Number', hint: 'E.g., KCB7-2000-C/2', controller: _busIdController, isRequired: true),
            _buildDetailField(label: 'Seat Number', hint: 'E.g., 40', controller: _seatController, isRequired: true, keyboardType: TextInputType.number),
            _buildDetailField(label: 'Total Price (Rs.)', hint: 'E.g., 1385.40', controller: _priceController, isRequired: true, keyboardType: TextInputType.number),
          ],
        ),
        const SizedBox(height: 20),
        
        // Floating Price Label (Updates in real-time)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _priceController,
              builder: (context, value, child) {
                // Safely format the price for display
                final price = value.text.isNotEmpty ? value.text : '0.00';
                return Text(
                  'PAYABLE: Rs. $price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- Section 3: Payment Details ---

  Widget _buildPaymentDetailsSection() {
    return _buildSectionCard(
      title: '3. Payment Details (Credit/Debit Card)', // Updated number
      icon: Icons.payment,
      children: [
        // Card Type Radio Buttons
        const Text('Select Card Type *', style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCardRadio('Visa'),
            _buildCardRadio('Mastercard'),
            _buildCardRadio('Amex'),
          ],
        ),
        const SizedBox(height: 15),

        // Card Holder Name
        _buildPaymentField('Card Holder Name *', 'Name on card', TextInputType.text),

        // Card Number
        _buildPaymentField('Card Number *', 'Enter 16 digit card number', TextInputType.number),
        
        // Expiration Date and CVV
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPaymentDropdown(label: 'Exp. Month *', items: _months, selectedValue: _selectedMonth, onChanged: (v) => setState(() => _selectedMonth = v)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildPaymentDropdown(label: 'Exp. Year *', items: _years, selectedValue: _selectedYear, onChanged: (v) => setState(() => _selectedYear = v)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildPaymentField('CVV *', '123', TextInputType.number, isCVN: true),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  // Utility to create consistent section wrappers
  Widget _buildSectionCard({required String title, required List<Widget> children, IconData icon = Icons.person}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            
            // Layout all children (which may include Wraps) in a column sequence
            ...children, 
          ],
        ),
      ),
    );
  }

  // Utility for general input fields (Traveller/Booking)
  Widget _buildDetailField({required String label, required String hint, required TextEditingController controller, bool isRequired = false, TextInputType keyboardType = TextInputType.text}) {
    return SizedBox(
      width: 250, // Fixed width for fields in Wrap layout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              children: isRequired
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: accentColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Utility for Payment Card Radio Buttons
  Widget _buildCardRadio(String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _cardType,
          activeColor: primaryColor,
          onChanged: (String? val) => setState(() => _cardType = val),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Utility for Payment Card Text Fields
  Widget _buildPaymentField(String label, String hint, TextInputType keyboardType, {bool isCVN = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          TextFormField(
            keyboardType: keyboardType,
            obscureText: isCVN,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: accentColor, width: 2),
              ),
              suffixIcon: isCVN ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
            ),
          ),
          if (isCVN)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '3 or 4 digit security code.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  // Utility for Payment Card Dropdowns
  Widget _buildPaymentDropdown({required String label, required List<String> items, required String? selectedValue, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
              style: const TextStyle(color: Colors.black, fontSize: 16),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Your Booking', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Traveller Details
            _buildTravellerDetailsSection(),
            
            // 2. Booking Details (New input section)
            _buildBookingDetailsSection(),
            
            // 3. Payment Details
            _buildPaymentDetailsSection(),
            
            const SizedBox(height: 40),

            // Final Proceed Button
            ElevatedButton(
              onPressed: () {
                // Simple validation check (using traveller details as minimum check)
                if (_nameController.text.isEmpty || _mobileController.text.isEmpty || _emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required Traveller details.')),
                  );
                  return;
                }
                
                // Simulate Payment Process
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Processing secure payment of Rs. ${_priceController.text} for ${_routeController.text}...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor, 
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text(
                'Confirm & Pay Securely', 
                style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w900)
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}