import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../core/theme/app_theme.dart';
import '../utils/phone_validator.dart';
import '../utils/rwandan_phone_input_formatter.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.labelText,
    this.validator,
    this.textInputAction,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<PhoneInputField> createState() => PhoneInputFieldState();
}

class PhoneInputFieldState extends State<PhoneInputField> {
  Country _selectedCountry = Country(
    phoneCode: '250',
    countryCode: 'RW',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'Rwanda',
    example: '250123456789',
    displayName: 'Rwanda (RW) [+250]',
    displayNameNoCountryCode: 'Rwanda (RW)',
    e164Key: '250-RW-0',
  );

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Country Code Picker
          InkWell(
            onTap: widget.enabled ? _showCountryPicker : null,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            child: Container(
              height: 56, // Match TextFormField height
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(
                  color: AppTheme.thinBorderColor,
                  width: AppTheme.thinBorderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _selectedCountry.flagEmoji,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    '+${_selectedCountry.phoneCode}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.textSecondaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          // Phone Number Input
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              textInputAction: widget.textInputAction,
              enabled: widget.enabled,
              onTap: widget.onTap,
              inputFormatters: [
                PhoneInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: widget.labelText ?? 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '788606765',
                hintStyle: AppTheme.hintText,
              ),
              validator: widget.validator ?? PhoneValidator.validateInternationalPhone,
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: AppTheme.backgroundColor,
        textStyle: Theme.of(context).textTheme.bodyMedium!,
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppTheme.textHintColor.withOpacity(0.2),
            ),
          ),
        ),
        searchTextStyle: Theme.of(context).textTheme.bodyMedium!,
      ),
      // Allow all countries
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  String get fullPhoneNumber {
    final phoneNumber = widget.controller.text.trim();
    if (phoneNumber.isEmpty) return '';
    return '+${_selectedCountry.phoneCode}$phoneNumber';
  }

  void setPhoneNumber(String fullNumber) {
    if (fullNumber.startsWith('+')) {
      // Try to find the country code
      for (final country in CountryService().getAll()) {
        if (fullNumber.startsWith('+${country.phoneCode}')) {
          setState(() {
            _selectedCountry = country;
            widget.controller.text = fullNumber.substring(country.phoneCode.length + 1);
          });
          return;
        }
      }
    }
    // If no country code found, just set the number
    widget.controller.text = fullNumber;
  }
} 