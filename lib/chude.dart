import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cauhoi.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ChudePage extends StatefulWidget {
  const ChudePage({super.key});

  @override
  _ChudePageState createState() => _ChudePageState();
}

class _ChudePageState extends State<ChudePage> {
  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    categories = fetchCategories();
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('http://192.168.1.8:5254/api/Category/user'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((category) => Category.fromJson(category)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
  Future<void> createExam(int categoryId) async {
    // Lấy userId từ SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('userId') ?? 0;  // Default là 0 nếu không có userId

    if (userId == 0) {
      // Nếu không có userId, thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: Không tìm thấy thông tin người dùng!')));
      return;
    }

    // Tạo dữ liệu JSON để gửi tới API
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
      // Thành công, thông báo cho người dùng
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final int examId = responseBody['examId'];  // Giả sử API trả về examId
      prefs.setInt('examId', examId);  // Lưu examId vào SharedPreferences
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tạo bài thi thành công!')));
    } else {
      // Lỗi khi tạo bài thi
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tạo bài thi!')));
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
      ),
      body: FutureBuilder<List<Category>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có chủ đề nào.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final category = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    createExam(category.categoryId);

                    // Điều hướng đến trang câu hỏi khi người dùng nhấn vào một chủ đề
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionPage(categoryId: category.categoryId),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 40,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.categoryName,
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  category.description,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}


class Category {
  final int categoryId;
  final String categoryName;
  final String description;

  Category({required this.categoryId, required this.categoryName, required this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      description: json['description'],
    );
  }
}
