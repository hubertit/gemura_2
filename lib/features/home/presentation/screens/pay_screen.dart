import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

enum PayMethod { reference, qr, contact }

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;
  PayMethod _method = PayMethod.reference;
  String? _scannedQR;

  @override
  void dispose() {
    _referenceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (!mounted) return;
    setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(message: 'Payment successful!'),
      );
    Navigator.of(context).pop();
  }

  void _scanQR() async {
    // Placeholder for QR scan logic
    setState(() {
      _scannedQR = 'REF-QR-123456';
      _referenceController.text = _scannedQR!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(color: AppTheme.thinBorderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _methodButton(PayMethod.reference, Icons.numbers, 'Reference'),
                  _methodButton(PayMethod.qr, Icons.qr_code, 'Scan QR'),
                  _methodButton(PayMethod.contact, Icons.contacts, 'Contact'),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_method == PayMethod.reference) ...[
                    Text('Reference Code', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _referenceController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Enter reference code',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Reference required' : null,
                    ),
                  ],
                  if (_method == PayMethod.qr) ...[
                    Text('Scan QR Code', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _referenceController,
                            style: AppTheme.bodySmall,
                            decoration: const InputDecoration(
                              hintText: 'Scanned reference will appear here',
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                            border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                            tooltip: 'Scan QR',
                            onPressed: _scanQR,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_method == PayMethod.contact) ...[
                    Text('Select Contact', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactController,
                            style: AppTheme.bodySmall,
                            decoration: const InputDecoration(
                              hintText: 'Phone number',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact required' : null,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                            border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.contacts, color: AppTheme.primaryColor),
                            tooltip: 'Select from contacts',
                            onPressed: () async {
                              final selected = await showModalBottomSheet<String>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => _ContactPickerSheet(),
                              );
                              if (selected != null && selected.isNotEmpty) {
                                setState(() {
                                  _contactController.text = selected;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacing24),
                  PrimaryButton(
                    label: 'Pay',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodButton(PayMethod method, IconData icon, String label) {
    final selected = _method == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _method = method;
          _referenceController.clear();
          _contactController.clear();
          _scannedQR = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.primaryColor : AppTheme.textHintColor, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: selected ? AppTheme.primaryColor : AppTheme.textHintColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  List<Contact> _contacts = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _loading = true);
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() => _loading = false);
      return;
    }
    final contacts = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      _contacts = contacts.where((c) => (c.phones?.isNotEmpty ?? false)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = 400.0;
    return SafeArea(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Text('Select Contact', style: AppTheme.titleMedium),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_contacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No contacts found', style: AppTheme.bodySmall),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _contacts.length,
                    itemBuilder: (context, i) {
                      final c = _contacts[i];
                      final phone = c.phones!.isNotEmpty ? c.phones!.first.value ?? '' : '';
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(c.displayName ?? '', style: AppTheme.bodySmall),
                        subtitle: Text(phone, style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor)),
                        onTap: () => Navigator.of(context).pop(phone),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppTheme.actionSheetBottomSpacing),
            ],
          ),
        ),
      ),
    );
  }
} 