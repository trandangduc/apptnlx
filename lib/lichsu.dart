import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'lishsuchitiet.dart';
import 'package:intl/intl.dart';  // Thêm thư viện intl để định dạng ngày tháng

// Model Exam
class Exam {
  final int examId;
  final int userId;
  final int categoryId;
  final String categoryName;  // Thêm trường categoryName để lưu tên chủ đề
  final DateTime examDate;
  final int score;

  Exam({
    required this.examId,
    required this.userId,
    required this.categoryId,
    required this.categoryName,  // Khởi tạo tên chủ đề
    required this.examDate,
    required this.score,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      examId: json['examId'],
      userId: json['userId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Không rõ', // Thêm xử lý nếu không có categoryName
      examDate: DateTime.parse(json['examDate']),
      score: json['score'],
    );
  }

  // Phương thức để định dạng ngày tháng
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(examDate); // Định dạng ngày tháng theo kiểu dd/MM/yyyy
  }
}

class LichSuPage extends StatefulWidget {
  @override
  _LichSuPageState createState() => _LichSuPageState();
}

class _LichSuPageState extends State<LichSuPage> {
  late int userId; // Lưu userId

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Lấy userId từ SharedPreferences
  Future<void> _loadUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId') ?? 0;
    });
  }

  // Hàm lấy lịch sử làm bài từ API
  Future<List<Exam>> fetchExamHistory(int userId) async {
    final response = await http.get(Uri.parse('http://192.168.1.73:5254/api/exam/history/$userId'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((exam) => Exam.fromJson(exam)).toList();
    } else {
      throw Exception('Failed to load exam history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử làm bài'),
        backgroundColor: Colors.teal,
      ),
      body: userId == 0
          ? const Center(child: CircularProgressIndicator()) // Hiển thị loading nếu chưa có userId
          : FutureBuilder<List<Exam>>(
        future: fetchExamHistory(userId), // Lấy lịch sử làm bài theo userId
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có lịch sử làm bài.'));
          } else {
            var exams = snapshot.data!;
            return ListView.builder(
              itemCount: exams.length,
              itemBuilder: (context, index) {
                var exam = exams[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  child:ListTile(
                    title: Text('Chủ đề: ${exam.categoryName}'),
                    subtitle: Text('Ngày làm bài: ${DateFormat('dd/MM/yyyy').format(exam.examDate)}'),
                    trailing: Text('Điểm: ${exam.score}'),
                    onTap: () {
                      // Chuyển hướng đến trang chi tiết bài thi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamDetailPage(examId: exam.examId),
                        ),
                      );
                    },
                  )
                );
              },
            );
          }
        },
      ),
    );
  }
}
