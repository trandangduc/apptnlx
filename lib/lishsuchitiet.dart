import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Cấu trúc Question để phù hợp với dữ liệu từ API
class Question {
  final int questionId;
  final String questionText;
  final String userAnswer; // Câu trả lời của người dùng
  final String correctAnswer; // Đáp án đúng

  Question({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      questionText: json['questionText'],
      userAnswer: json['userAnswer'], // Câu trả lời của người dùng
      correctAnswer: json['correctAnswer'], // Đáp án đúng
    );
  }
}

// Hàm lấy câu hỏi từ API
Future<List<Question>> fetchQuestions(int examId) async {
  final response = await http.get(Uri.parse('http://192.168.1.73:5254/api/exam/questions/$examId'));

  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((question) => Question.fromJson(question)).toList();
  } else {
    throw Exception('Failed to load questions');
  }
}

class ExamDetailPage extends StatefulWidget {
  final int examId;

  ExamDetailPage({required this.examId});

  @override
  _ExamDetailPageState createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  late Future<List<Question>> futureQuestions;

  @override
  void initState() {
    super.initState();
    futureQuestions = fetchQuestions(widget.examId); // Lấy câu hỏi khi trang được tải
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài thi'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Question>>(
        future: futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có câu hỏi cho bài thi này.'));
          } else {
            var questions = snapshot.data!;
            return ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                var question = questions[index];
                bool isAnswerCorrect = question.userAnswer == question.correctAnswer;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  child: ListTile(
                    title: Text(question.questionText),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Câu trả lời của bạn: ${question.userAnswer}",
                            style: TextStyle(
                              color: isAnswerCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Đáp án đúng: ${question.correctAnswer}",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isAnswerCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                            ),
                          ),
                      ],
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
