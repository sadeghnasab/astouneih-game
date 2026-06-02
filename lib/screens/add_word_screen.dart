import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({Key? key}) : super(key: key);

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final TextEditingController _languageController = TextEditingController(
    text: 'تاتی',
  );
  final TextEditingController _cityController = TextEditingController(
    text: 'دانسفهان',
  );
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();

  bool isSubmitting = false;
  String playerName = 'جنگجو';

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'جنگجو';
    });
  }

  Future<void> _submitWord() async {
    if (_wordController.text.trim().isEmpty ||
        _translationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً کلمه و معنی آن را بنویس!',
            style: TextStyle(fontFamily: 'Piramooz'),
          ),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    bool success = await ApiService.sendNewWord(
      playerName,
      _languageController.text.trim(),
      _cityController.text.trim(),
      _wordController.text.trim(),
      _translationController.text.trim(),
    );

    setState(() => isSubmitting = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'کلمه شما با موفقیت به گنجینه اضافه شد! 📜',
            style: TextStyle(fontFamily: 'Piramooz', fontSize: 18),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _wordController.clear();
      _translationController.clear();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ارتباط با سرور قطع شد. دوباره تلاش کن!',
            style: TextStyle(fontFamily: 'Piramooz'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'مشارکت در گنجینه ✉️',
          style: TextStyle(fontFamily: 'Piramooz', color: AppColors.epicGold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.epicGold),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'کلمات اصیل شهر خود را برای ما بفرستید تا در آپدیت‌های بعدی به بازی اضافه شوند.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),

            _buildTextField('زبان / گویش', _languageController, Icons.language),
            const SizedBox(height: 15),
            _buildTextField(
              'نام شهر یا روستا',
              _cityController,
              Icons.location_city,
            ),
            const SizedBox(height: 15),
            _buildTextField('کلمه اصیل', _wordController, Icons.text_fields),
            const SizedBox(height: 15),
            _buildTextField(
              'معنی فارسی',
              _translationController,
              Icons.translate,
              maxLines: 2,
            ),

            const SizedBox(height: 40),

            isSubmitting
                ? const CircularProgressIndicator(color: AppColors.epicGold)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bloodRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(
                          color: AppColors.epicGold,
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _submitWord();
                    },
                    child: const Text(
                      'ارسال به پشتیبانی 🚀',
                      style: TextStyle(
                        fontFamily: 'Piramooz',
                        fontSize: 24,
                        color: AppColors.epicGold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.epicGold,
          fontFamily: 'Piramooz',
          fontSize: 20,
        ),
        prefixIcon: Icon(icon, color: AppColors.epicGold),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.epicGold, width: 2),
        ),
        filled: true,
        fillColor: Colors.black45,
      ),
    );
  }
}
