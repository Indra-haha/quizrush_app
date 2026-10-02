import 'package:flutter/material.dart';

import '../engine/kalkulator_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_bar.dart';

class KalkulatorPage extends StatefulWidget {
  const KalkulatorPage({super.key});

  @override
  State<KalkulatorPage> createState() => KalkulatorPageState();
}

class KalkulatorPageState extends State<KalkulatorPage> {
  final TextEditingController _displayController = TextEditingController();

  late String _operation;
  String _result = '';

  final List<String> _gridButtons = [
    'C',
    '⌫',
    'G/G',
    'Sn',
    '7',
    '8',
    '9',
    '÷',
    '4',
    '5',
    '6',
    '×',
    '1',
    '2',
    '3',
    '-',
    '0',
    '.',
    ',',
    '+',
  ];

  @override
  void initState() {
    super.initState();
    _operation = "";
    _displayController.addListener(() {
      _hitung(); // Live evaluasi terpanggil otomatis setiap ada perubahan teks
    });
  }

  void _onGridButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _clear();
        return;
      }

      if (value == '⌫') {
        if (_displayController.text.isNotEmpty) {
          if (_displayController.text.endsWith(' ')) {
            _displayController.text = _displayController.text.substring(
              0,
              _displayController.text.length - 3,
            );
          } else {
            _displayController.text = _displayController.text.substring(
              0,
              _displayController.text.length - 1,
            );
          }
        }
        return;
      }

      if (['+', '-', '×', '÷'].contains(value)) {
        final String text = _displayController.text;
        _operation = text.contains(',') ? 'deret' : '';

        if (text.isEmpty) {
          if (value == '-') {
            _displayController.text = '-';
          }
          return;
        }

        if ((text.endsWith(',') || text.endsWith(', ')) && value == '-') {
          _displayController.text = text.endsWith(' ')
              ? '${text.substring(0, text.length - 1)}-'
              : '$text-';
          return;
        }

        final String core = text.trimRight();
        final bool prevOperator =
            core.isNotEmpty &&
            ['+', '-', '×', '÷'].contains(core[core.length - 1]);

        if (value == '-') {
          _displayController.text = prevOperator ? '$core -' : '$core - ';
          return;
        }

        if (prevOperator) {
          _displayController.text =
              '${core.substring(0, core.length - 1).trimRight()} $value ';
          return;
        }

        _displayController.text += ' $value ';
        return;
      }

      if (value == 'G/G') {
        _operation = 'ganjil_genap';
        _hitung();
        return;
      }

      if (value == 'Sn') {
        _operation = 'deret';
        _hitung();
        return;
      }

      _displayController.text += value;
    });
  }

  void _hitung() {
    final String raw = _displayController.text.trim();
    if (raw.isEmpty) {
      setState(() => _result = '');
      return;
    }

    if (_operation == 'ganjil_genap') {
      final bool validAngka = RegExp(r'^-?\d+$').hasMatch(raw);

      if (!validAngka) {
        setState(() => _result = 'Masukkan angka valid!');
        return;
      }

      final int? angka = int.tryParse(raw);
      if (angka == null) {
        setState(() => _result = 'Masukkan 1 angka bulat!');
        return;
      }

      setState(() {
        _result =
            '$angka adalah Bilangan ${angka % 2 == 0 ? "GENAP" : "GANJIL"}';
      });
      return;
    }

    if (_operation == 'deret') {
      final List<String> items = raw.split(RegExp(r',+'));
      double total = 0;
      int count = 0;
      for (var item in items) {
        double? val = double.tryParse(item.trim().replaceAll(',', '.'));
        if (val != null) {
          total += val;
          count++;
        }
      }
      setState(() {
        _result = count > 0
            ? 'Total $count data deret = ${_numFormat(total)}'
            : 'Nilai tidak valid!';
      });
      return;
    }

    // Live Evaluasi menggunakan KalkulatorEngine.parse
    final Expr? parsed = KalkulatorEngine.parse(raw);
    if (parsed == null) {
      setState(() => _result = '');
      return;
    }

    final double? hasil = KalkulatorEngine.hitung(parsed);
    if (hasil == null) {
      setState(() => _result = 'Tidak dapat membagi dengan nol!');
      return;
    }

    setState(() {
      _result = ' ${_numFormat(hasil)}';
    });
  }

  String _numFormat(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  void _clear() {
    _displayController.clear();
    _result = '';
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderBar(title: 'Kalkulator'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _displayController,
                    readOnly: true,
                    showCursor: true,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.calculatorDisplay,
                    decoration: InputDecoration(
                      labelText: _operation == 'deret'
                          ? 'Mode Deret (pisahkan koma)'
                          : _operation == 'ganjil_genap'
                          ? 'Mode Ganjil / Genap'
                          : 'Mode Kalkulator',
                      border: OutlineInputBorder(borderRadius: AppRadius.md),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space9),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.md,
                    ),
                    child: Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.calculatorDisplay,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: AppColors.primarySoft,
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gridButtons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final btn = _gridButtons[index];
                Color btnColor = AppColors.textOnPrimary;
                Color textColor = AppColors.textPrimary;

                if (btn == '=') {
                  btnColor = AppColors.primary;
                  textColor = AppColors.textOnPrimary;
                } else if (btn == 'C' || btn == '⌫') {
                  btnColor = AppStatus.danger;
                  textColor = AppColors.textOnPrimary;
                } else if (['+', '-', '×', '÷', 'G/G', 'Sn'].contains(btn)) {
                  btnColor = AppColors.surfaceSoft;
                  textColor = AppColors.textPrimary;
                }

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                  ),
                  onPressed: () => _onGridButtonPressed(btn),
                  child: Text(btn, style: AppTextStyles.calculatorResult),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
