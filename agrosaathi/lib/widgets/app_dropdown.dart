import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Accessible Dropdown with distinct top label.
/// Overflow-proof with isExpanded and text ellipsis.
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final void Function(T?) onChanged;
  final String? hint;
  final bool isRequired;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          hint: hint != null
              ? Text(
                  hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
