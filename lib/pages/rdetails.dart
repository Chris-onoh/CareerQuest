import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class RDetails extends StatefulWidget {
  final String resultData;

  const RDetails({Key? key, required this.resultData}) : super(key: key);

  @override
  State<RDetails> createState() => _RDetailsState();
}

class _RDetailsState extends State<RDetails> {
  List<String> generatedContents = [];

  @override
  void initState() {
    super.initState();
    _generateContent();
  }

  Future<void> _generateContent() async {
    try {
      final response = await aiCompose(widget.resultData);
      setState(() {
        generatedContents = response?.split('||') ?? ['No content generated'];
      });
    } catch (e) {
      setState(() {
        generatedContents = ['Error generating content'];
      });
      print('Error generating content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: generatedContents.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var content in generatedContents)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    content.trim(),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
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
}

Future<String?> aiCompose(String content) async {
  var apiKey =
      "AIzaSyBtv33JbCvJ7eddVcqVgb8Te9T94pJZOYg"; // Your API key goes here
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  final prompt =
      """You are an AI model tasked with assessing career choices for users based on their assessment data. 
      This is the user data:\n$content
      Now, with this data, suggest the top 10 career job titles that seem like a good fit for the user. 
      the format is to be like, "you" have this that , "you" should be , "you" this you this, not "the user this, the user that",
      for each career suggestion put this character in the text "||" to separate them. because in the code,
       the parsing will use this to seperate each job title
      Ensure the analysis is constructive and informative, and that the user understands their career prospects.
      """;
  final response = await model.generateContent([Content.text(prompt)]);
  return response?.text;
}
