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
    final response = await http.get(Uri.parse('http://192.168.1.8:5254/api/exam/history/$userId'));

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
        title: const Text(
          'Lịch sử làm bài',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Chức năng lọc có thể thêm sau này
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[700]!, Colors.teal[50]!],
            stops: const [0.0, 0.3],
          ),
        ),
        child: userId == 0
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        )
            : FutureBuilder<List<Exam>>(
          future: fetchExamHistory(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_edu,
                      color: Colors.teal,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có lịch sử làm bài',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hãy làm một bài kiểm tra để xem kết quả tại đây',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Điều hướng đến trang làm bài
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Làm bài mới',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              var exams = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    var exam = exams[index];

                    // Xác định màu sắc dựa trên điểm số
                    Color scoreColor = Colors.orange;
                    if (exam.score >= 8) {
                      scoreColor = Colors.green;
                    } else if (exam.score >= 5) {
                      scoreColor = Colors.blue;
                    } else {
                      scoreColor = Colors.red;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExamDetailPage(examId: exam.examId),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Chủ đề: ${exam.categoryName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd/MM/yyyy - HH:mm')
                                              .format(exam.examDate),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scoreColor.withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(30),
                                        border: Border.all(
                                          color: scoreColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Điểm: ${exam.score}',
                                        style: TextStyle(
                                          color: scoreColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Xem chi tiết ›',
                                    style: TextStyle(
                                      color: Colors.teal[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
