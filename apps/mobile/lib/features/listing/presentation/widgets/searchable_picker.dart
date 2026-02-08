import 'package:flutter/material.dart';

/// A searchable picker widget that displays options in a bottom sheet modal.
/// Used for selecting from a large list of options like brands.
class SearchablePicker extends StatefulWidget {
  final String label;
  final List<PickerOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String? placeholder;
  final bool isRequired;
  final String? errorText;

  const SearchablePicker({
    super.key,
    required this.label,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    this.placeholder,
    this.isRequired = false,
    this.errorText,
  });

  @override
  State<SearchablePicker> createState() => _SearchablePickerState();
}

class _SearchablePickerState extends State<SearchablePicker> {
  void _showPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchablePickerModal(
        options: widget.options,
        selectedValue: widget.selectedValue,
        onSelected: (value) {
          widget.onChanged(value);
          Navigator.of(context).pop();
        },
        title: widget.label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = widget.options
        .where((o) => o.value == widget.selectedValue)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Picker Button
        InkWell(
          onTap: _showPicker,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.errorText != null
                    ? Colors.red
                    : const Color(0xFFD1D5DB),
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedOption?.label ?? widget.placeholder ?? 'Select...',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedOption != null
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
        // Error Text
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
        ],
      ],
    );
  }
}

/// Option model for the picker
class PickerOption {
  final String value;
  final String label;

  const PickerOption({required this.value, required this.label});
}

/// The bottom sheet modal content
class _SearchablePickerModal extends StatefulWidget {
  final List<PickerOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;
  final String title;

  const _SearchablePickerModal({
    required this.options,
    this.selectedValue,
    required this.onSelected,
    required this.title,
  });

  @override
  State<_SearchablePickerModal> createState() => _SearchablePickerModalState();
}

class _SearchablePickerModalState extends State<_SearchablePickerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<PickerOption> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_filterOptions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((o) => o.label.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEC4899)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 8),
          // Options list
          Flexible(
            child: _filteredOptions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: bottomPadding + 16),
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filteredOptions[index];
                      final isSelected = option.value == widget.selectedValue;

                      return ListTile(
                        onTap: () => widget.onSelected(option.value),
                        title: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF111827),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFFEC4899))
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
