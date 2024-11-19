import 'package:ble_flutter/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class CustomField extends StatelessWidget {
  const CustomField({
    super.key,
    required this.label,
    required this.commandController,
    this.keyboardType,
  });

  final String label;
  final TextEditingController commandController;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: SizeConfig.getHeight(40),
        child: TextFormField(
          controller: commandController,
          keyboardType: keyboardType ?? TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '$label cannot be empty!';
            }
            return null;
          },
          style: TextStyle(
            fontSize: SizeConfig.getFontSize(14),
          ),
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: SizeConfig.getFontSize(14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(SizeConfig.getWidth(8)),
                ),
              )),
        ),
      ),
    );
  }
}
