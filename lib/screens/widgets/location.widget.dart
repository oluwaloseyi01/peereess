import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peereess/core/num_extension.dart';
import 'package:peereess/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class LocationWidget extends StatefulWidget {
  const LocationWidget({super.key});

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  late FocusNode _fullNameFocus;
  late FocusNode _deliveryAddressFocus;

  @override
  void initState() {
    super.initState();
    _fullNameFocus = FocusNode();
    _deliveryAddressFocus = FocusNode();

    // Auto-focus the full name field after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fullNameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _deliveryAddressFocus.dispose();
    super.dispose();
  }

  static const List<String> states = [
    "Abia",
    "Adamawa",
    "Akwa Ibom",
    "Anambra",
    "Bauchi",
    "Bayelsa",
    "Benue",
    "Borno",
    "Cross River",
    "Delta",
    "Ebonyi",
    "Edo",
    "Ekiti",
    "Enugu",
    "Gombe",
    "Imo",
    "Jigawa",
    "Kaduna",
    "Kano",
    "Katsina",
    "Kebbi",
    "Kogi",
    "Kwara",
    "Lagos",
    "Nasarawa",
    "Niger",
    "Ogun",
    "Ondo",
    "Osun",
    "Oyo",
    "Plateau",
    "Rivers",
    "Sokoto",
    "Taraba",
    "Yobe",
    "Zamfara",
    "Abuja",
  ];

  static const List<String> phoneCodes = ["+234", "+1"];

  static InputDecoration _fieldDecoration({String? hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  static TextStyle get _labelStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );

  Widget _sectionLabel(String text) => Text(text, style: _labelStyle);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FULL NAME
        _sectionLabel("Full Name"),
        5.getHeightWhiteSpacing,
        TextFormField(
          focusNode: _fullNameFocus,
          controller: auth.receiverFullNameController,
          validator: (value) {
            final v = value?.trim() ?? "";
            if (v.isEmpty) return "Full name is required";
            if (v.length < 3) return "Enter valid name";
            return null;
          },
          decoration: _fieldDecoration(
            prefix: const Icon(Icons.person_outline, size: 18),
          ),
        ),

        18.getHeightWhiteSpacing,

        // PHONE
        _sectionLabel("Phone Number"),
        5.getHeightWhiteSpacing,
        Row(
          children: [
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                value: auth.phoneCodeController.text.isEmpty
                    ? null
                    : auth.phoneCodeController.text,
                hint: const Text("Code"),
                items: phoneCodes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) auth.phoneCodeController.text = v;
                },
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                decoration: _fieldDecoration(),
              ),
            ),
            10.getWidthWhiteSpacing,
            Expanded(
              child: TextFormField(
                controller: auth.deliveryPhoneNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  final v = value?.trim() ?? "";
                  if (v.isEmpty) return "Phone is required";
                  if (v.length < 10) return "Enter valid phone number";
                  return null;
                },
                decoration: _fieldDecoration(
                  prefix: const Icon(Icons.phone_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),

        18.getHeightWhiteSpacing,

        // STATE
        _sectionLabel("State"),
        5.getHeightWhiteSpacing,
        DropdownButtonFormField<String>(
          value: auth.statesController.text.isEmpty
              ? null
              : auth.statesController.text,
          hint: const Text("Select state"),
          items: states
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) auth.statesController.text = v;
          },
          validator: (v) => v == null || v.isEmpty ? "State is required" : null,
          decoration: _fieldDecoration(
            prefix: const Icon(Icons.location_city_outlined, size: 18),
          ),
        ),

        18.getHeightWhiteSpacing,

        // ADDRESS
        _sectionLabel("Full Address"),
        5.getHeightWhiteSpacing,
        TextFormField(
          controller: auth.deliveryAddressController,
          focusNode: _deliveryAddressFocus,
          validator: (value) {
            final v = value?.trim() ?? "";
            if (v.isEmpty) return "Address is required";
            if (v.length < 5) return "Enter valid address";
            return null;
          },
          decoration: _fieldDecoration(
            hint: "e.g. 12 Broad Street, Ikeja",
            prefix: const Icon(Icons.home_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}
