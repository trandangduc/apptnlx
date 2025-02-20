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
      Uri.parse('http://192.168.1.73:5254/api/exam/update-score/$examId'),
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
    final response = await http.get(Uri.parse('http://192.168.1.73:5254/api/Question/ByCategory/$categoryId'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((question) => Question.fromJson(question)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<List<Answer>> fetchAnswers(int questionId) async {
    final response = await http.get(Uri.parse('http://192.168.1.73:5254/api/Answer/ByQuestion/$questionId'));

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
      Uri.parse('http://192.168.1.73:5254/api/ExamDetail/Create'),
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
        title: const Text('Danh sách câu hỏi'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Question>>(
        future: questions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có câu hỏi nào.'));
          } else {
            final question = snapshot.data![currentQuestionIndex];
            return FutureBuilder<List<Answer>>(
              future: fetchAnswers(question.questionId),
              builder: (context, answerSnapshot) {
                if (answerSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (answerSnapshot.hasError) {
                  return Center(child: Text('Error: ${answerSnapshot.error}'));
                } else if (!answerSnapshot.hasData || answerSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có đáp án nào.'));
                } else {
                  final answers = answerSnapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.content,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: answers.length,
                          itemBuilder: (context, answerIndex) {
                            final answer = answers[answerIndex];
                            bool isSelected = question.selectedAnswer == answer.answerOption;
                            bool isCorrect = answer.answerOption == question.CorrectAnswer;

                            // Chỉ tô màu sau khi người dùng đã chọn đáp án
                            Color tileColor = Colors.white;
                            Color textColor = Colors.black;

                            if (question.selectedAnswer != null) {
                              // Nếu người dùng đã chọn câu trả lời
                              if (isCorrect) {
                                tileColor = Colors.green.shade100;  // Tô màu xanh cho đáp án đúng
                                textColor = Colors.green;  // Chữ màu xanh cho đáp án đúng
                              } else if (isSelected) {
                                tileColor = Colors.red.shade100;  // Tô màu đỏ cho đáp án sai
                                textColor = Colors.red;  // Chữ màu đỏ cho đáp án sai
                              }
                            }

                            return Container(
                              color: tileColor,
                              child: ListTile(
                                title: Text(
                                  answer.answerContent,
                                  style: TextStyle(color: textColor),
                                ),
                                leading: Radio<String>(
                                  value: answer.answerOption,
                                  groupValue: question.selectedAnswer,
                                  onChanged: (value) {
                                    setState(() {
                                      question.selectedAnswer = value;
                                      submitAnswer(question.questionId, value!, question.CorrectAnswer);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16.0),
                        // Hiển thị điểm
                        Text('Điểm của bạn: $score', style: TextStyle(fontSize: 18.0)),
                        const SizedBox(height: 16.0),
                        if (currentQuestionIndex < snapshot.data!.length - 1)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                currentQuestionIndex++;
                              });
                            },
                            child: const Text('Kế tiếp'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () async {
                              // Cập nhật điểm bài thi
                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                              final int examId = prefs.getInt('examId') ?? 0;

                              if (examId == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: Không tìm thấy bài thi!')));
                                return;
                              }

                              // Gửi điểm tới server để cập nhật
                              await updateExamScore(examId, score);

                              // Hiển thị thông báo kết thúc bài thi
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Kết thúc bài làm'),
                                    content: Text('Bạn đã hoàn thành bài làm.\nĐiểm của bạn: $score'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (context) => const MainPage()),
                                          );
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text('Kết thúc'),
                          )
                        ,
                      ],
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
  final String CorrectAnswer;
  String? selectedAnswer;

  Question({required this.questionId, required this.content, required this.CorrectAnswer, this.selectedAnswer});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['questionId'],
      content: json['content'],
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
