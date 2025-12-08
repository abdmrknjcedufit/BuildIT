import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/item_provider.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'package:file_picker/file_picker.dart';

class UserAddItemScreen extends StatefulWidget {
  const UserAddItemScreen({super.key});

  @override
  State<UserAddItemScreen> createState() => _UserAddItemScreenState();
}

class _UserAddItemScreenState extends State<UserAddItemScreen> {
  final ItemProvider _itemProvider = ItemProvider();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _minRentalPeriodController = TextEditingController();
  final TextEditingController _maxRentalPeriodController = TextEditingController();

  String? _titleError;
  String? _descriptionError;
  String? _priceError;
  String? _itemTypeError;
  String? _conditionError;

  bool _isLoading = false;
  bool _isCompressing = false;

  final List<String> _itemTypes = ['Građevinska mašina', 'Alat', 'Oprema', 'Drugo'];
  final List<String> _conditions = ['Novo', 'Kao novo', 'Dobro', 'Srednje', 'Loše'];
  String? _selectedItemType;
  String? _selectedCondition;

  List<Uint8List> _compressedImageBytes = [];
  List<String> _compressedBase64Images = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _minRentalPeriodController.dispose();
    _maxRentalPeriodController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imagesString;
      if (_compressedBase64Images.isNotEmpty) {
        imagesString = _compressedBase64Images.join(',');
      }

      var insertRequest = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'itemType': _selectedItemType,
        'status': 'Available',
        'condition': _selectedCondition,
        'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        'model': _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        'year': _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text.trim()),
        'minRentalPeriod': _minRentalPeriodController.text.trim().isEmpty ? null : int.tryParse(_minRentalPeriodController.text.trim()),
        'maxRentalPeriod': _maxRentalPeriodController.text.trim().isEmpty ? null : int.tryParse(_maxRentalPeriodController.text.trim()),
        'images': imagesString,
      };

      await _itemProvider.insert(insertRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Artikal je uspješno kreiran'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri kreiranju artikla: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateInputs() {
    final titleVal = _titleController.text;
    final descriptionVal = _descriptionController.text;
    final priceVal = _priceController.text;

    final titleValidation = inputRequired(titleVal);
    final descriptionValidation = inputRequired(descriptionVal);
    final priceValidation = _validatePrice(priceVal);
    final itemTypeValidation = _selectedItemType == null ? 'Tip artikla je obavezan' : null;
    final conditionValidation = _selectedCondition == null ? 'Stanje je obavezno' : null;

    setState(() {
      _titleError = titleValidation;
      _descriptionError = descriptionValidation;
      _priceError = priceValidation;
      _itemTypeError = itemTypeValidation;
      _conditionError = conditionValidation;
    });

    return _titleError == null &&
        _descriptionError == null &&
        _priceError == null &&
        _itemTypeError == null &&
        _conditionError == null;
  }

  String? _validatePrice(String value) {
    if (value.isEmpty) {
      return 'Cijena je obavezna';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Cijena mora biti pozitivan broj';
    }
    return null;
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        _isCompressing = true;
      });

      List<Uint8List> newCompressedBytes = [];
      List<String> newCompressedBase64 = [];

      for (int i = 0; i < result.files.length; i++) {
        var platformFile = result.files[i];

        if (platformFile.path == null) {
          continue;
        }

        try {
          File imageFile = File(platformFile.path!);

          if (!imageFile.existsSync()) {
            continue;
          }

          Uint8List imageBytes = await imageFile.readAsBytes();
          Uint8List? compressedBytes = await _compressImage(imageBytes);

          if (compressedBytes == null) {
            compressedBytes = imageBytes;
          }

          String base64Image = base64Encode(compressedBytes);

          if (base64Image.length > 10000000) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Slika ${i + 1} je prevelika. Molimo odaberite manju sliku.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }

          newCompressedBytes.add(Uint8List.fromList(compressedBytes));
          newCompressedBase64.add(base64Image);
        } catch (fileError) {
          print('Greška pri procesiranju fajla ${i + 1}: $fileError');
        }
      }

      setState(() {
        _compressedImageBytes.addAll(newCompressedBytes);
        _compressedBase64Images.addAll(newCompressedBase64);
        _isCompressing = false;
      });
    } catch (e) {
      setState(() {
        _isCompressing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri odabiru slika: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 800,
        targetHeight: 800,
      );

      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _compressedImageBytes.removeAt(index);
      _compressedBase64Images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Dodaj novi artikal'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dodavanje novog artikla',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Naziv artikla *',
                    prefixIcon: const Icon(Icons.title, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _titleError,
                    errorMaxLines: 2,
                  ),
                  onChanged: (value) {
                    if (_titleError != null) {
                      setState(() {
                        _titleError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Opis *',
                    prefixIcon: const Icon(Icons.description, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _descriptionError,
                    errorMaxLines: 2,
                  ),
                  onChanged: (value) {
                    if (_descriptionError != null) {
                      setState(() {
                        _descriptionError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cijena (KM) *',
                          prefixIcon: const Icon(Icons.attach_money, color: AppColors.darkGray, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _priceError,
                          errorMaxLines: 2,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        onChanged: (value) {
                          if (_priceError != null) {
                            setState(() {
                              _priceError = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedItemType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Tip artikla *',
                          prefixIcon: const Icon(Icons.category, color: AppColors.darkGray, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _itemTypeError,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        items: _itemTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedItemType = value;
                              _itemTypeError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Stanje *',
                    prefixIcon: const Icon(Icons.check_circle, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _conditionError,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: _conditions.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(
                        condition,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCondition = value;
                        _conditionError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'Marka (opcionalno)',
                          prefixIcon: const Icon(Icons.branding_watermark, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: 'Model (opcionalno)',
                          prefixIcon: const Icon(Icons.model_training, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Godina proizvodnje (opcionalno)',
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minRentalPeriodController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minimalni period iznajmljivanja (dani)',
                          prefixIcon: const Icon(Icons.access_time, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _maxRentalPeriodController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Maksimalni period iznajmljivanja (dani)',
                          prefixIcon: const Icon(Icons.access_time, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Slike',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isCompressing)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _isCompressing ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Odaberi slike'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: AppColors.white,
                  ),
                ),
                if (_compressedImageBytes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_compressedImageBytes.length, (index) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.darkGray),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _compressedImageBytes[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Otkaži'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: AppColors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('Dodaj artikal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

