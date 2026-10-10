import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    required this.query,
    required this.onChanged,
    super.key,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: query)
        ..selection = TextSelection.collapsed(offset: query.length),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search channels',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: () => onChanged(''),
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}