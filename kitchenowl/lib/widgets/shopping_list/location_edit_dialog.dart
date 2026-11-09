import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:kitchenowl/helpers/url_launcher.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/location_service.dart';

class LocationEditDialog extends StatefulWidget {
  final ShoppingListLocation? location;

  const LocationEditDialog({super.key, this.location});

  @override
  State<LocationEditDialog> createState() => _LocationEditDialogState();
}

class _LocationEditDialogState extends State<LocationEditDialog> {
  late final TextEditingController nameController;
  late final TextEditingController latitudeController;
  late final TextEditingController longitudeController;
  late int radius;
  bool loadingPosition = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.location?.name);
    latitudeController = TextEditingController(
      text: widget.location?.latitude.toString(),
    );
    longitudeController = TextEditingController(
      text: widget.location?.longitude.toString(),
    );
    radius = widget.location?.radius ?? ShoppingListLocation.defaultRadius;
    if (widget.location == null && LocationService.isLocationSupported) {
      _useCurrentPosition(requestPermission: false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  double? get latitude {
    final value = _parse(latitudeController.text);
    return value != null && value >= -90 && value <= 90 ? value : null;
  }

  double? get longitude {
    final value = _parse(longitudeController.text);
    return value != null && value >= -180 && value <= 180 ? value : null;
  }

  bool get isValid => latitude != null && longitude != null;

  Future<void> _useCurrentPosition({bool requestPermission = true}) async {
    setState(() => loadingPosition = true);
    final position = await LocationService.getCurrentPosition(
      requestPermission: requestPermission,
    );
    if (!mounted) return;
    setState(() {
      loadingPosition = false;
      if (position != null) {
        latitudeController.text = position.latitude.toStringAsFixed(6);
        longitudeController.text = position.longitude.toStringAsFixed(6);
      }
    });
    if (position == null && requestPermission) {
      showSnackbar(
        context: context,
        width: null,
        content: Text(AppLocalizations.of(context)!.locationUnavailable),
      );
    }
  }

  void _submit() {
    if (!isValid) return;
    final name = nameController.text.trim();
    Navigator.of(context).pop(ShoppingListLocation(
      name: name.isEmpty ? null : name,
      latitude: latitude!,
      longitude: longitude!,
      radius: radius,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final coordinateFormatter = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
    ];
    const coordinateKeyboard = TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.location == null
          ? AppLocalizations.of(context)!.shoppingListLocationAdd
          : AppLocalizations.of(context)!.shoppingListLocationEdit),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!
                      .shoppingListLocationNameHint,
                  prefixIcon: const Icon(Icons.storefront_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latitudeController,
                      keyboardType: coordinateKeyboard,
                      inputFormatters: coordinateFormatter,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.latitude,
                        errorText: latitudeController.text.isNotEmpty &&
                                latitude == null
                            ? ''
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: longitudeController,
                      keyboardType: coordinateKeyboard,
                      inputFormatters: coordinateFormatter,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.longitude,
                        errorText: longitudeController.text.isNotEmpty &&
                                longitude == null
                            ? ''
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (LocationService.isLocationSupported)
                    TextButton.icon(
                      onPressed: loadingPosition ? null : _useCurrentPosition,
                      icon: loadingPosition
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(
                        AppLocalizations.of(context)!.locationUseCurrent,
                      ),
                    ),
                  if (isValid)
                    TextButton.icon(
                      onPressed: () => openUrl(
                        context,
                        'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=17/$latitude/$longitude',
                      ),
                      icon: const Icon(Icons.map_rounded),
                      label: Text(
                        AppLocalizations.of(context)!.locationShowOnMap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.radius),
                  const Spacer(),
                  Text(
                    '$radius m',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              Slider(
                value: radius.toDouble(),
                min: ShoppingListLocation.minRadius.toDouble(),
                max: ShoppingListLocation.maxRadius.toDouble(),
                divisions: (ShoppingListLocation.maxRadius -
                        ShoppingListLocation.minRadius) ~/
                    50,
                label: '$radius m',
                onChanged: (value) => setState(() => radius = value.round()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(
              Theme.of(context).disabledColor,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: isValid ? _submit : null,
          child: Text(widget.location == null
              ? AppLocalizations.of(context)!.add
              : AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
