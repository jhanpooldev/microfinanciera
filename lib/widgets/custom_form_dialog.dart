import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showCustomFormDialog(
  BuildContext context,
  String title,
  Map<String, String> fields, {
  Map<String, dynamic>? initialValues,
}) async {
  final formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {
    for (var key in fields.keys)
      key: TextEditingController(text: initialValues?[key]?.toString() ?? ''),
  };

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: TextFormField(
                controller: controllers[entry.key],
                decoration: InputDecoration(labelText: entry.value),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Guardar'),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final data = {
                for (var e in controllers.entries) e.key: e.value.text
              };
              Navigator.pop(context, data);
            }
          },
        ),
      ],
    ),
  );
}
