import 'package:flutter/material.dart';
import 'chude.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cauhoi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lichsu.dart';
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trang chính',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

// Hàm lấy chủ đề ngẫu nhiên từ API
  Future<Map<String, dynamic>> fetchRandomCategory() async {
    final String apiUrl = 'http://192.168.1.73:5254/api/Category/user';  // API của bạn để lấy chủ đề
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(response.body);
        if (categories.isNotEmpty) {
          final randomCategory = (categories..shuffle()).first;
          return randomCategory; // Trả về một chủ đề ngẫu nhiên
        }
        throw Exception('Không có chủ đề');
      } else {
        throw Exception('Không thể tải chủ đề');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chính'),
        automaticallyImplyLeading: false, // Ẩn nút quay lại
        backgroundColor: Colors.teal,  // Màu nền AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Đảm bảo giao diện không bị tràn
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildButton(context, 'Thi theo bộ đề ngẫu nhiên', Icons.shuffle, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chọn thi theo bộ đề ngẫu nhiên!')),
                );
                fetchRandomCategory().then((category) {
                  createExam(category['categoryId']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionPage(categoryId: category['categoryId']),
                    ),
                  );
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                });
              }),
              const SizedBox(height: 16.0),
              _buildButton(context, 'Thi theo chủ đề', Icons.category, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chọn thi theo chủ đề!')),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChudePage()),
                );
              }),
              const SizedBox(height: 16.0),
              _buildButton(context, 'Xem lịch sử làm bài', Icons.error, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xem lịch sử làm bài')),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(

                    builder: (context) => LichSuPage(), // Thay 1 bằng ID người dùng thực tế
                  ),
                );
              }),

            ],
          ),
        ),
      ),
    );
  }
  // Tạo bài thi với categoryId
  Future<void> createExam(int categoryId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;

    if (userId == 0) {

      return;
    }

    final Map<String, dynamic> examData = {
      'UserId': userId,
      'CategoryId': categoryId,
    };

    final response = await http.post(
      Uri.parse('http://192.168.1.73:5254/api/exam'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(examData),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final int examId = responseBody['examId'];
      prefs.setInt('examId', examId);

    } else {

    }
  }
  Widget _buildButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.teal,  // Sử dụng backgroundColor thay vì primary
        foregroundColor: Colors.white, // Sử dụng foregroundColor thay vì onPrimary
        shadowColor: Colors.black.withOpacity(0.3),
        elevation: 5, // Tạo hiệu ứng đổ bóng cho nút
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32.0, color: Colors.white),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
