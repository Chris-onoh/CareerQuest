import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<String> aiGenQuest(List<String> askedQuestions) async {
  final apiKey = "AIzaSyDVT-ouWFL5GfXBnAEfk0QutavVwpk_3ac";

  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final askedQuestionsString = askedQuestions.join(', ');
  final content = [
    Content.text(
        """Generate a single, short career determinant question (for kids) that hasn't been asked yet. Don't ask questions that make the user choose between two like "A or B", instead ask about "A" only or "B" only. These questions will be used to predict possible career choices for the user. 
        Here are the questions that have already been asked: $askedQuestionsString. Do not repeat these questions. Make sure to include art and medicine related questions, do not focus on only one career section, be diverse on job titles. Use the following template:
        Would you love to play and create games on computers or tablets?
Do you enjoy drawing, painting, or making crafts?
Would you love to help others feel better when they are sick or hurt?
Are you great at solving puzzles or figuring out how things work?
Do you like to explore and discover new things?
Would you love to tell stories or write your own adventures?
Do you enjoy singing, dancing, or playing musical instruments?
Are you curious about how buildings are made or how machines work?
Do you like playing outside and being active?
Would you love to cook and bake yummy treats in the kitchen?
Do you enjoy reading books or listening to stories?
Are you interested in learning about different animals and plants?
Do you like playing sports or games with your friends?
Would you love to design and decorate your own room or space?
Are you good at helping your friends or family when they need it?
Do you enjoy learning new things and trying out different activities?
        Ensure the questions are short, direct, and cover various aspects of career and work, and personality preferences. This is used to help determine best careers for kids.""")
  ];
  final response = await model.generateContent(content);
  return response.text!;
}

Future<String> aiGenAnalysis(Map<String, String> questionResponses) async {
  final apiKey = "AIzaSyDVT-ouWFL5GfXBnAEfk0QutavVwpk_3ac";

  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final content = [
    Content.text(
        """This is the data from a survey taken to analyze user intuition and preferences: \n$questionResponses. Based on this data, suggest, in a heirachy from the most positive and most likely down, the top 10 real-world job industries and career paths that seem like a good fit for the user. Do not make up fake job titles; for example, because a person likes solving puzzles, doesn't mean they want to be a puzzle solver. Be very tactical and logical in your responses and decisions. Provide a short description and reasoning for each suggestion.""")
  ];
  final response = await model.generateContent(content);
  return response.text!;
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String> _question;
  Map<String, String> questionResponses = {};
  List<String> askedQuestions = [];
  String? _currentQuestion;
  int? _selectedPreference;

  @override
  void initState() {
    super.initState();
    _initQuestion();
  }

  void _initQuestion() {
    setState(() {
      _selectedPreference = null; // Reset the selected preference
    });
    _question = _generateQuestion();
  }

  Future<String> _generateQuestion() async {
    try {
      return await aiGenQuest(askedQuestions);
    } catch (e) {
      print('Error fetching question: $e');
      // Add a small delay before retrying
      await Future.delayed(Duration(seconds: 1));
      return await _generateQuestion(); // Retry on error
    }
  }

  void _handleResponse(int preference) {
    setState(() {
      if (_currentQuestion != null) {
        questionResponses[_currentQuestion!] = _preferenceToString(preference);
        askedQuestions.add(_currentQuestion!);
      }
      if (questionResponses.length < 30) {
        _initQuestion(); // Refresh the UI to display the next question
      } else {
        // All questions answered, generate analysis
        _generateAnalysis();
      }
    });
  }

  String _preferenceToString(int preference) {
    switch (preference) {
      case 0:
        return "Strongly Negative";
      case 1:
        return "Negative";
      case 2:
        return "Neutral";
      case 3:
        return "Positive";
      case 4:
        return "Strongly Positive";
      default:
        return "";
    }
  }

  Future<void> _generateAnalysis() async {
    try {
      final analysis = await aiGenAnalysis(questionResponses);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Analysis"),
          content: Text(analysis),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error generating analysis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Career Assessment"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                "Main Question:",
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<String>(
                    future: _question,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        _currentQuestion = snapshot.data;
                        return Column(
                          children: [
                            Text(
                              snapshot.data ?? "Loading...",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20.0,
                              ),
                            ),
                            SizedBox(height: 20.0),
                            Column(
                              children: List.generate(5, (index) {
                                return CustomRadioListTile(
                                  title: _preferenceToString(index),
                                  value: index,
                                  groupValue: _selectedPreference,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPreference = value;
                                    });
                                    _handleResponse(value!);
                                  },
                                );
                              }),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _handleResponse(-1); // Skipping question
                },
                child: Text("Skip question"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomRadioListTile extends StatefulWidget {
  final String title;
  final int value;
  final int? groupValue;
  final ValueChanged<int?> onChanged;

  const CustomRadioListTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  _CustomRadioListTileState createState() => _CustomRadioListTileState();
}

class _CustomRadioListTileState extends State<CustomRadioListTile> {
  @override
  Widget build(BuildContext context) {
    return RadioListTile(
      title: Text(widget.title),
      value: widget.value,
      groupValue: widget.groupValue,
      onChanged: (value) {
        widget.onChanged(value as int?);
      },
    );
  }

  @override
  void didUpdateWidget(covariant CustomRadioListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupValue != oldWidget.groupValue) {
      setState(() {});
    }
  }
}

void main() {
  runApp(HomePage());
}
