import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum RequestType { link, qr, direct }

class RequestPaymentScreen extends StatefulWidget {
  const RequestPaymentScreen({super.key});

  @override
  State<RequestPaymentScreen> createState() => _RequestPaymentScreenState();
}

class _RequestPaymentScreenState extends State<RequestPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  RequestType _type = RequestType.direct;
  String? _generatedLink;
  String? _generatedQR;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (_type == RequestType.direct) {
          ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.successSnackBar(message: 'Payment request sent!'),
    );
      Navigator.of(context).pop();
    } else if (_type == RequestType.link) {
      setState(() {
        _generatedLink = 'https://pay.ihuzo.rw/finance/request/123456';
        _generatedQR = null;
      });
    } else if (_type == RequestType.qr) {
      setState(() {
        _generatedQR = 'QR_CODE_DATA';
        _generatedLink = 'https://pay.ihuzo.rw/finance/request/123456';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Payment'),
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
            // Request type selector
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
                  _typeButton(RequestType.link, Icons.link, 'Payment Link'),
                  _typeButton(RequestType.qr, Icons.qr_code, 'QR Code'),
                  _typeButton(RequestType.direct, Icons.send, 'Send Direct'),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (_generatedLink != null)
              _ResultBox(
                icon: Icons.link,
                label: 'Share this payment link:',
                value: _generatedLink!,
                onClose: () => setState(() => _generatedLink = null),
              ),
            if (_generatedQR != null)
              _QRResultBox(
                link: _generatedLink!,
                onClose: () => setState(() { _generatedQR = null; _generatedLink = null; }),
              ),
            if (_generatedLink == null && _generatedQR == null)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_type == RequestType.direct) ...[
                      Text('Recipient', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _recipientController,
                              style: AppTheme.bodySmall,
                              decoration: const InputDecoration(
                                hintText: 'Phone number or email',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Recipient required' : null,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
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
                                    _recipientController.text = selected;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    Text('Amount', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _amountController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Enter amount',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (_type == RequestType.direct && (v == null || v.trim().isEmpty)) return 'Amount required';
                        if (v != null && v.trim().isNotEmpty) {
                          final n = num.tryParse(v);
                          if (n == null || n <= 0) return 'Enter a valid amount';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text('Note (optional)', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spacing8),
                    TextFormField(
                      controller: _noteController,
                      style: AppTheme.bodySmall,
                      decoration: const InputDecoration(
                        hintText: 'Add a note (optional)',
                        prefixIcon: Icon(Icons.edit_note_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    PrimaryButton(
                      label: _type == RequestType.direct
                          ? 'Send Request'
                          : _type == RequestType.link
                              ? 'Generate Link'
                              : 'Show QR Code',
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

  Widget _typeButton(RequestType type, IconData icon, String label) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _generatedLink = null;
          _generatedQR = null;
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

class _ResultBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onClose;
  const _ResultBox({required this.icon, required this.label, required this.value, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing24),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        border: Border.all(color: AppTheme.thinBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppTheme.infoSnackBar(message: 'Copied to clipboard'),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                tooltip: 'Share',
                onPressed: () async {
                  await SharePlus.instance.share(ShareParams(text: value));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QRResultBox extends StatelessWidget {
  final String link;
  final VoidCallback onClose;
  const _QRResultBox({required this.link, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(link)}';
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing24),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        border: Border.all(color: AppTheme.thinBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Show this QR code:', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Center(
            child: Image.network(qrUrl, width: 200, height: 200, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppTheme.spacing16),
          SelectableText(
            link,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
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