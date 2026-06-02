import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminScreen extends StatefulWidget {
  final String adminPhone;

  // فرمانده باید شماره خودش رو نشون بده تا سرور بهش اجازه دسترسی بده
  const AdminScreen({Key? key, required this.adminPhone}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> usersList = [];
  bool isLoading = true;

  final String serverUrl = "https://astoniea-server.liara.run";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // 📡 دریافت لیست تمام سربازان از سرور
  Future<void> _fetchUsers() async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/admin/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"adminPhone": widget.adminPhone}),
      );

      if (response.statusCode == 200) {
        setState(() {
          usersList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        _showError("دسترسی غیرمجاز یا خطای سرور!");
      }
    } catch (e) {
      _showError("ارتباط با پایگاه داده قطع شد!");
    }
  }

  // ✏️ ارسال دستور ویرایش پرونده به سرور
  Future<void> _updateUser(
    String targetPhone,
    String newName,
    int newScore,
    int newKulalieh,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/admin/edit-user'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "adminPhone": widget.adminPhone,
          "targetPhone": targetPhone,
          "newName": newName,
          "newScore": newScore,
          "newKulalieh": newKulalieh,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ پرونده با موفقیت آپدیت شد!")),
        );
        _fetchUsers(); // رفرش کردن لیست برای دیدن تغییرات
      } else {
        _showError("خطا در اعمال تغییرات!");
      }
    } catch (e) {
      _showError("خطای شبکه!");
    }
  }

  void _showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 📝 فرم پاپ‌آپ برای ویرایش اطلاعات یک سرباز
  void _showEditDialog(Map<String, dynamic> user) {
    TextEditingController nameCtrl = TextEditingController(
      text: user['username'],
    );
    TextEditingController scoreCtrl = TextEditingController(
      text: user['score'].toString(),
    );
    TextEditingController kulaliehCtrl = TextEditingController(
      text: user['kulalieh'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF2A2D3E),
            title: Text(
              'ویرایش: ${user['phone']}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'نام کاربری',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.amber),
                    decoration: const InputDecoration(
                      labelText: 'امتیاز نبرد',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextField(
                    controller: kulaliehCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.cyanAccent),
                    decoration: const InputDecoration(
                      labelText: 'تعداد کولالیه',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'لغو',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _updateUser(
                    user['phone'],
                    nameCtrl.text,
                    int.tryParse(scoreCtrl.text) ?? user['score'],
                    int.tryParse(kulaliehCtrl.text) ?? user['kulalieh'],
                  );
                },
                child: const Text('ذخیره تغییرات'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          title: const Text(
            'اتاق مخفی فرماندهی 👑',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent.shade700,
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.redAccent),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: usersList.length,
                itemBuilder: (context, index) {
                  final user = usersList[index];
                  final bool isAdmin = user['role'] == 'admin';

                  return Card(
                    color: const Color(0xFF2A2D3E),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAdmin
                            ? Colors.redAccent
                            : Colors.blueGrey,
                        child: Icon(
                          isAdmin ? Icons.security : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        user['username'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'شماره: ${user['phone']}\nامتیاز: ${user['score']} | کولالیه: ${user['kulalieh']}',
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.greenAccent),
                        onPressed: () => _showEditDialog(user),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
