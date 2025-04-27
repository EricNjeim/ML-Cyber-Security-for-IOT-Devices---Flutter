import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iotframework/core/di/injection_container.dart';
import 'package:iotframework/core/providers/providers.dart';
import 'package:iotframework/domain/entities/device.dart';
import 'package:iotframework/data/models/device_model.dart';

/// Screen for editing device details
class DeviceEditScreen extends ConsumerStatefulWidget {
  final Device? device;
  final bool isNew;

  const DeviceEditScreen({
    super.key,
    this.device,
    this.isNew = false,
  });

  @override
  ConsumerState<DeviceEditScreen> createState() => _DeviceEditScreenState();
}

class _DeviceEditScreenState extends ConsumerState<DeviceEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ipAddressController;
  late TextEditingController _macAddressController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with device data or empty strings for new device
    _nameController = TextEditingController(
      text: widget.device?.name ?? '',
    );

    _ipAddressController = TextEditingController(
      text: widget.device?.ipAddress ?? '',
    );

    _macAddressController = TextEditingController(
      text: widget.device?.macAddress ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipAddressController.dispose();
    _macAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceRepository =
          ref.read(ServiceLocator.deviceRepositoryProvider);

      final deviceData = DeviceModel(
        id: widget.device?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        ipAddress: _ipAddressController.text,
        macAddress: _macAddressController.text.toUpperCase(),
        type: widget.device?.type ?? DeviceType.other,
        status: widget.device?.status ?? DeviceStatus.offline,
        lastSeen: widget.device?.lastSeen ?? DateTime.now(),
        metadata: widget.device?.metadata,
      );

      final result = widget.isNew
          ? await deviceRepository.addDevice(deviceData)
          : await deviceRepository.updateDevice(deviceData);

      result.fold(
        (device) {
          // Refresh devices list
          ref.refresh(devicesProvider);

          // Return to previous screen
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        },
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Add Device' : 'Edit Device'),
        backgroundColor: Colors.greenAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              // Device Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'Enter a name for this device',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.device_hub),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Device name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // IP Address Field
              TextFormField(
                controller: _ipAddressController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: 'e.g., 192.168.1.100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.router),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'IP address is required';
                  }

                  // Simple IP validation
                  final ipRegex = RegExp(
                      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
                  if (!ipRegex.hasMatch(value)) {
                    return 'Enter a valid IP address';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // MAC Address Field
              TextFormField(
                controller: _macAddressController,
                decoration: const InputDecoration(
                  labelText: 'MAC Address',
                  hintText: 'e.g., AA:BB:CC:DD:EE:FF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                inputFormatters: [
                  // Allow only hex characters and colons for MAC address
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]')),
                  LengthLimitingTextInputFormatter(17),
                  // Format MAC address as user types
                  _MacAddressFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'MAC address is required';
                  }

                  // MAC address validation (allowing various formats)
                  final cleanMac =
                      value.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
                  if (cleanMac.length != 12) {
                    return 'Enter a valid MAC address';
                  }

                  return null;
                },
                onChanged: (value) {
                  // Convert to uppercase for consistency
                  final cursorPos = _macAddressController.selection;
                  _macAddressController.text = value.toUpperCase();
                  _macAddressController.selection = cursorPos;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isNew ? 'Add Device' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formatter for MAC address input
class _MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-hex characters
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');

    // Insert colons for proper MAC address format
    if (newText.length > 2) {
      final buffer = StringBuffer();
      for (int i = 0; i < newText.length; i++) {
        buffer.write(newText[i]);
        if ((i + 1) % 2 == 0 && i < newText.length - 1) {
          buffer.write(':');
        }
      }
      newText = buffer.toString();
    }

    // Limit to 17 characters (12 hex digits + 5 colons)
    if (newText.length > 17) {
      newText = newText.substring(0, 17);
    }

    // Adjust cursor position if we've added a colon just before
    final newSelection = TextSelection.collapsed(
      offset: newValue.selection.end + (newText.length - newValue.text.length),
    );

    return TextEditingValue(
      text: newText,
      selection: newSelection,
    );
  }
}
