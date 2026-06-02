import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<dynamic> allUsers = [];
  bool isLoading = true;
  String myPhone = '';

  // ⚠️ لینک سرور لیارای شما
  final String serverUrl = 'https://astoniea-server.liara.run';

  @override
  void initState() {
    super.initState();
    _fetchArmyList();
  }

  // 📡 دریافت لیست کل سربازان از گاوصندوق ابری
  Future<void> _fetchArmyList() async {
    final prefs = await SharedPreferences.getInstance();
    myPhone = prefs.getString('phone') ?? '';

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/admin/users'),
        headers: {'Content-Type': 'application/json'},
        // 🛡️ ارسال شماره فرمانده برای تایید هویت امنیتی
        body: jsonEncode({'adminPhone': myPhone}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          allUsers = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        _showError('شما دسترسی فرماندهی ندارید!');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showError('خطا در ارتباط با سرور مرکزی');
      setState(() => isLoading = false);
    }
  }

  // ✏️ ارسال دستور تغییر اطلاعات یک سرباز به سرور
  Future<void> _updateSoldier(
    String targetPhone,
    String newName,
    int newScore,
  ) async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/admin/edit-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminPhone': myPhone,
          'targetPhone': targetPhone,
          'newName': newName,
          'newScore': newScore,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccess('اطلاعات سرباز با موفقیت ویرایش شد! ⚔️');
        _fetchArmyList(); // رفرش کردن لیست
      } else {
        _showError('خطا در اعمال تغییرات!');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showError('خطا در ارتباط با سرور');
      setState(() => isLoading = false);
    }
  }

  // 📋 پنجره‌ی صدور دستور ویرایش
  void _showEditDialog(Map<String, dynamic> user) {
    final TextEditingController nameController = TextEditingController(
      text: user['username'],
    );
    final TextEditingController scoreController = TextEditingController(
      text: user['score'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.epicGold, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'ویرایش پرونده سرباز',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Morvarid', color: AppColors.epicGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user['phone'],
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Morvarid',
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'نام کاربری',
                labelStyle: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Morvarid',
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.epicGold),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Morvarid',
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'امتیاز جهانی',
                labelStyle: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Morvarid',
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.epicGold),
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'لغو',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Morvarid',
                fontSize: 18,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bloodRed,
            ),
            onPressed: () {
              Navigator.pop(context);
              int parsedScore = int.tryParse(scoreController.text) ?? 0;
              _updateSoldier(user['phone'], nameController.text, parsedScore);
            },
            child: const Text(
              'اعمال دستور',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Morvarid',
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Morvarid')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Morvarid')),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        centerTitle: true,
        title: const Text(
          'اتاق فرماندهی کل 👑',
          style: TextStyle(
            fontFamily: 'Morvarid',
            color: AppColors.epicGold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.epicGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.epicGold),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final user = allUsers[index];
                final bool isAdmin = user['role'] == 'admin';

                return Card(
                  color: isAdmin
                      ? Colors.blueGrey.shade900
                      : Colors.grey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: isAdmin ? Colors.blueAccent : Colors.white24,
                      width: isAdmin ? 2 : 1,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 15),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? Colors.blueAccent
                          : AppColors.bloodRed,
                      child: Icon(
                        isAdmin ? Icons.security : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      user['username'],
                      style: TextStyle(
                        fontFamily: 'Morvarid',
                        color: isAdmin ? Colors.blueAccent : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['phone'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '🏆 امتیاز: ${user['score']}',
                          style: const TextStyle(
                            fontFamily: 'Morvarid',
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.edit_attributes,
                        color: AppColors.epicGold,
                        size: 35,
                      ),
                      onPressed: () => _showEditDialog(user),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
