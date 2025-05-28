import 'package:flutter/material.dart';
import 'chatAI.dart';
import 'chude.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cauhoi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lichsu.dart';
import 'main.dart';
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
    final String apiUrl = 'http://192.168.1.8:5254/api/Category/user';  // API của bạn để lấy chủ đề
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

        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              // TODO: Thêm logic đăng xuất tại đây nếu cần (xóa token, session, vv...)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()), // thay bằng trang đăng nhập của bạn
              );
            },
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Banner hoặc logo ứng dụng
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildAnimatedButton(
                  context,
                  'Thi theo bộ đề ngẫu nhiên',
                  Icons.shuffle,
                  Colors.teal,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chọn thi theo bộ đề ngẫu nhiên!'),
                        backgroundColor: Colors.teal,
                        behavior: SnackBarBehavior.floating,
                      ),
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
                  },
                ),
                const SizedBox(height: 20.0),
                _buildAnimatedButton(
                  context,
                  'Thi theo chủ đề',
                  Icons.category,
                  Colors.deepPurple,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chọn thi theo chủ đề!'),
                        backgroundColor: Colors.deepPurple,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChudePage()),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                _buildAnimatedButton(
                  context,
                  'Xem lịch sử làm bài',
                  Icons.history,
                  Colors.amber.shade700,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Xem lịch sử làm bài'),
                        backgroundColor: Colors.amber.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LichSuPage(),
                      ),
                    );
                  },
                ),
                _buildAnimatedButton(
                  context,
                  'Học với AI thông qua biển báo',
                  Icons.smart_toy,
                  Colors.green.shade600,
                      () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chuyển đến phần học với AI!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIBienBaoPage(), // Thay thế bằng trang bạn đã tạo
                      ),
                    );
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

// Widget cho các nút bấm với hiệu ứng
  Widget _buildAnimatedButton(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
      Uri.parse('http://192.168.1.8:5254/api/exam'),
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

}
