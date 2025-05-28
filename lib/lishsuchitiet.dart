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
  final response = await http.get(Uri.parse('http://192.168.1.8:5254/api/exam/questions/$examId'));

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
        title: const Text('Chi tiết bài thi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Hiển thị thông tin về bài thi
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Thông tin bài thi'),
                  content: const Text('Đây là thông tin chi tiết về bài thi và các câu trả lời của bạn.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.tealAccent],
            stops: [0.0, 0.3],
          ),
        ),
        child: FutureBuilder<List<Question>>(
          future: futureQuestions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  )
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh function here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, color: Colors.grey, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'Không có câu hỏi cho bài thi này.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            } else {
              var questions = snapshot.data!;
              int correctAnswers = questions.where((q) => q.userAnswer == q.correctAnswer).length;

              return Column(
                children: [
                  // Summary card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Kết quả của bạn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSummaryItem(
                              icon: Icons.question_answer_outlined,
                              value: '${questions.length}',
                              label: 'Tổng số câu',
                              color: Colors.blue,
                            ),
                            _buildSummaryItem(
                              icon: Icons.check_circle_outline,
                              value: '$correctAnswers',
                              label: 'Câu đúng',
                              color: Colors.green,
                            ),
                            _buildSummaryItem(
                              icon: Icons.cancel_outlined,
                              value: '${questions.length - correctAnswers}',
                              label: 'Câu sai',
                              color: Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: correctAnswers / questions.length,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            correctAnswers / questions.length > 0.7 ? Colors.green :
                            correctAnswers / questions.length > 0.4 ? Colors.orange : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(correctAnswers / questions.length * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Questions list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        var question = questions[index];
                        bool isAnswerCorrect = question.userAnswer == question.correctAnswer;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isAnswerCorrect ? Colors.green.shade100 : Colors.red.shade100,
                              width: 1,
                            ),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isAnswerCorrect ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                isAnswerCorrect ? Icons.check : Icons.close,
                                color: isAnswerCorrect ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              'Câu ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              question.questionText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.questionText,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildAnswerRow(
                                      label: 'Câu trả lời của bạn:',
                                      answer: question.userAnswer,
                                      isCorrect: isAnswerCorrect,
                                      icon: isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                                      color: isAnswerCorrect ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildAnswerRow(
                                      label: 'Đáp án đúng:',
                                      answer: question.correctAnswer,
                                      isCorrect: true,
                                      icon: Icons.check_circle,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerRow({
    required String label,
    required String answer,
    required bool isCorrect,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                answer,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
