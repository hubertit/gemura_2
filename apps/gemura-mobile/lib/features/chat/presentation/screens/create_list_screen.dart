import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final TextEditingController _listNameController = TextEditingController();
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _listNameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _canSave = _listNameController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        title: Text(
          'New list',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave ? _createList : null,
            child: Text(
              'Done',
              style: AppTheme.bodyMedium.copyWith(
                color: _canSave 
                    ? AppTheme.primaryColor 
                    : AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List name section
            Text(
              'List name',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                border: Border.all(
                  color: AppTheme.thinBorderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _listNameController,
                decoration: InputDecoration(
                  hintText: 'Examples: Work, Friends',
                  hintStyle: AppTheme.hintText,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing12,
                  ),
                ),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
                autofocus: true,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Any list you create becomes a filter at the top of your Chats tab.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            // Included section
            Text(
              'Included',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                border: Border.all(
                  color: AppTheme.thinBorderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _addPeopleOrGroups,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          color: AppTheme.textPrimaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Add people or groups',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createList() {
    final listName = _listNameController.text.trim();
    if (listName.isNotEmpty) {
      // TODO: Implement list creation logic
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('List "$listName" created successfully!'),
          backgroundColor: AppTheme.snackbarSuccessColor,
        ),
      );
    }
  }

  void _addPeopleOrGroups() {
    // TODO: Implement add people or groups functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add people or groups functionality coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }
} 