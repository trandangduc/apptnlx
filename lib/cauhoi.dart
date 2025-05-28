import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mainpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionPage extends StatefulWidget {
  final int categoryId;
  const QuestionPage({super.key, required this.categoryId});
  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  late Future<List<Question>> questions;
  int currentQuestionIndex = 0;
  int score = 0; // Biến điểm

  @override
  void initState() {
    super.initState();
    questions = fetchQuestions(widget.categoryId);
  }

  Future<void> updateExamScore(int examId, int score) async {
    final response = await http.put(
      Uri.parse('http://192.168.1.8:5254/api/exam/update-score/$examId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(score),
    );
    if (response.statusCode == 200) {
      print('Điểm đã được cập nhật thành công');
    } else {
      print('Không thể cập nhật điểm');
    }
  }

  Future<List<Question>> fetchQuestions(int categoryId) async {
    final response = await http.get(Uri.parse('http://192.168.1.8:5254/api/Question/ByCategory/$categoryId'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((question) => Question.fromJson(question)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<List<Answer>> fetchAnswers(int questionId) async {
    final response = await http.get(Uri.parse('http://192.168.1.8:5254/api/Answer/ByQuestion/$questionId'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((answer) => Answer.fromJson(answer)).toList();
    } else {
      throw Exception('Failed to load answers');
    }
  }

  Future<void> submitAnswer(int questionId, String selectedAnswer, String correctAnswer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int examId = prefs.getInt('examId') ?? 0;
    if (examId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: Không tìm thấy bài thi!')));
      return;
    }
    final response = await http.post(
      Uri.parse('http://192.168.1.8:5254/api/ExamDetail/Create'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "ExamId": examId,
        "QuestionId": questionId,
        "SelectedAnswer": selectedAnswer,
        "IsCorrect": selectedAnswer == correctAnswer
      }),
    );
    if (response.statusCode == 200) {
      print('Answer submitted successfully');
    } else {
      print('Failed to submit answer');
    }
    // Cập nhật điểm nếu người dùng chọn đáp án đúng
    if (selectedAnswer == correctAnswer) {
      setState(() {
        score++; // Tăng điểm nếu đúng
      });
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Điểm: $score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Question>>(
        future: questions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Đã xảy ra lỗi: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        questions = fetchQuestions(widget.categoryId);
                      });
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
                  Icon(Icons.question_answer_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có câu hỏi nào.',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          } else {
            final question = snapshot.data![currentQuestionIndex];
            final totalQuestions = snapshot.data!.length;
            return FutureBuilder<List<Answer>>(
              future: fetchAnswers(question.questionId),
              builder: (context, answerSnapshot) {
                if (answerSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                } else if (answerSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Lỗi tải đáp án: ${answerSnapshot.error}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!answerSnapshot.hasData || answerSnapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 60, color: Colors.amber),
                        SizedBox(height: 16),
                        Text(
                          'Không có đáp án nào cho câu hỏi này.',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                } else {
                  final answers = answerSnapshot.data!;
                  return Container(
                    color: Colors.grey[50],
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Progress indicator
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Câu ${currentQuestionIndex + 1}/$totalQuestions',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Còn lại: ${totalQuestions - currentQuestionIndex - 1} câu',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (currentQuestionIndex + 1) / totalQuestions,
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.teal,
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question card
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Câu hỏi:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.teal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          question.content,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        // Hiển thị hình ảnh nếu có
                                        if (question.image != null && question.image!.isNotEmpty)
                                          Column(
                                            children: [
                                              const SizedBox(height: 16),
                                              Container(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    question.image!,
                                                    fit: BoxFit.contain,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        height: 200,
                                                        alignment: Alignment.center,
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          color: Colors.teal,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 100,
                                                        alignment: Alignment.center,
                                                        color: Colors.grey[200],
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                                            const SizedBox(height: 8),
                                                            Text('Không thể tải hình ảnh',
                                                                style: TextStyle(color: Colors.grey[600])),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Answers section
                                  const Text(
                                    'Chọn đáp án:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ListView.separated(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: answers.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, answerIndex) {
                                      final answer = answers[answerIndex];
                                      bool isSelected = question.selectedAnswer == answer.answerOption;
                                      bool isCorrect = answer.answerOption == question.CorrectAnswer;
                                      // Style based on selection status
                                      Color borderColor = Colors.grey.shade300;
                                      Color backgroundColor = Colors.white;
                                      Color textColor = Colors.black87;
                                      IconData? trailingIcon;
                                      Color? trailingIconColor;
                                      if (question.selectedAnswer != null) {
                                        if (isCorrect) {
                                          borderColor = Colors.green;
                                          backgroundColor = Colors.green.shade50;
                                          textColor = Colors.green.shade800;
                                          trailingIcon = Icons.check_circle;
                                          trailingIconColor = Colors.green;
                                        } else if (isSelected) {
                                          borderColor = Colors.red;
                                          backgroundColor = Colors.red.shade50;
                                          textColor = Colors.red.shade800;
                                          trailingIcon = Icons.cancel;
                                          trailingIconColor = Colors.red;
                                        }
                                      } else if (isSelected) {
                                        borderColor = Colors.teal;
                                        backgroundColor = Colors.teal.shade50;
                                      }
                                      return InkWell(
                                        onTap: question.selectedAnswer == null
                                            ? () {
                                          setState(() {
                                            question.selectedAnswer = answer.answerOption;
                                            submitAnswer(question.questionId, answer.answerOption, question.CorrectAnswer);
                                          });
                                        }
                                            : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: borderColor, width: 1.5),
                                            color: backgroundColor,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected ? Colors.teal : Colors.grey.shade200,
                                                    border: Border.all(
                                                      color: isSelected ? Colors.teal.shade700 : Colors.grey.shade400,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      answer.answerOption,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected ? Colors.white : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    answer.answerContent,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: textColor,
                                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                                if (trailingIcon != null)
                                                  Icon(
                                                    trailingIcon,
                                                    color: trailingIconColor,
                                                    size: 24,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  // Navigation buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (currentQuestionIndex > 0)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              currentQuestionIndex--;
                                            });
                                          },
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Trước đó'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                            foregroundColor: Colors.black87,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 100),
                                      if (currentQuestionIndex < snapshot.data!.length - 1)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              currentQuestionIndex++;
                                            });
                                          },
                                          label: const Text('Câu tiếp'),
                                          icon: const Icon(Icons.arrow_forward),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        )
                                      else
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            // Kiểm tra tất cả các câu hỏi đã được trả lời chưa
                                            final allAnswered = snapshot.data!.every((q) => q.selectedAnswer != null);
                                            if (!allAnswered) {
                                              final confirmFinish = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('Xác nhận'),
                                                    content: const Text('Bạn chưa trả lời hết các câu hỏi. Bạn có chắc muốn kết thúc bài làm?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: const Text('Kiểm tra lại'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                                        child: const Text('Kết thúc'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              if (confirmFinish != true) {
                                                return;
                                              }
                                            }
                                            // Cập nhật điểm bài thi
                                            final SharedPreferences prefs = await SharedPreferences.getInstance();
                                            final int examId = prefs.getInt('examId') ?? 0;
                                            if (examId == 0) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Lỗi: Không tìm thấy bài thi!'))
                                              );
                                              return;
                                            }
                                            try {
                                              await updateExamScore(examId, score);
                                              // Hiển thị thông báo kết thúc bài thi
                                              if (context.mounted) {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      backgroundColor: Colors.white, // màu nền trắng
                                                      title: const Text('Kết thúc bài làm'),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 80,
                                                            height: 80,
                                                            decoration: BoxDecoration(
                                                              color: Colors.teal.shade50,
                                                              borderRadius: BorderRadius.circular(12), // hình vuông bo góc nhẹ
                                                            ),
                                                            child: Icon(
                                                              Icons.check_circle,
                                                              size: 50,
                                                              color: Colors.teal.shade400,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 20),
                                                          const Text(
                                                            'Bạn đã hoàn thành bài làm!',
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          Container(
                                                            padding: const EdgeInsets.all(15),
                                                            decoration: BoxDecoration(
                                                              color: Colors.teal.shade50,
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                const Text(
                                                                  'Điểm của bạn: ',
                                                                  style: TextStyle(fontSize: 18),
                                                                ),
                                                                Text(
                                                                  '$score',
                                                                  style: const TextStyle(
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.teal,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(context);
                                                            Navigator.pushReplacement(
                                                              context,
                                                              MaterialPageRoute(builder: (context) => const MainPage()),
                                                            );
                                                          },
                                                          child: const Text('Về trang chính'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi khi cập nhật điểm: $e'))
                                              );
                                            }
                                          },
                                          label: const Text('Kết thúc bài thi'),
                                          icon: const Icon(Icons.done_all),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}

class Question {
  final int questionId;
  final String content;
  final String? image; // Thêm trường image
  final String CorrectAnswer;
  String? selectedAnswer;

  Question({
    required this.questionId,
    required this.content,
    this.image, // Thêm trường image vào constructor
    required this.CorrectAnswer,
    this.selectedAnswer
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      content: json['content'],
      image: json['image'], // Lấy giá trị image từ API
      CorrectAnswer: json['correctAnswer'],
      selectedAnswer: null,
    );
  }
}

class Answer {
  final int answerId;
  final String answerContent;
  final String answerOption;

  Answer({required this.answerId, required this.answerContent, required this.answerOption});

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answerId: json['answerId'],
      answerContent: json['answerContent'],
      answerOption: json['answerOption'],
    );
  }
}