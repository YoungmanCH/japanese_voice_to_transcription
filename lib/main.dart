import 'package:flutter/material.dart';
import 'package:mecab_dart/mecab_dart.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'webview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Try entering your voice.'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  Mecab? _mecab;
  String _text = '';
  List<String> _nouns = [];
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initMecab();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('status: $status'),
      onError: (error) => debugPrint('error: $error'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          setState(() {
            _text = result.recognizedWords;
          });
          if (_mecab != null) {
            final nouns = await _extractNouns(_text);
            setState(() {
              _nouns = nouns;
            });
          }
        },
      );
    } else {
      debugPrint('Error');
    }
  }

  Future<List<String>> _extractNouns(String text) async {
    if (_mecab != null) {
      final nodes = _mecab!.parse(text);
      var nouns = nodes
          .where((node) => node.features.contains('名詞'))
          .map((node) => node.surface)
          .toList();
      return nouns.cast<String>();
    } else {
      debugPrint('Error: MeCab is not initialized');
      return [];
    }
  }

  Future<void> _initMecab() async {
    _mecab = Mecab();
    if (_mecab != null) {
      await _mecab!.init('assets/ipadic', true);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _mecab?.destroy();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val')
      );
      if (available) {
        setState(() {
          _isListening = true;
          _text = '';
        });
        _speech.listen(
          onResult: (val) async {
            setState(() {
              _text = val.recognizedWords;
            });
            if (_mecab != null) {
              await _mecab!.init('assets/ipadic', true);
              final nouns = await _extractNouns(_text);
              setState(() {
                _nouns = nouns;
              });
            }
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('音声認識結果:'),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _text,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
            ),
          ),
          const Text('抽出した名詞:'),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<String>>(
              future: _extractNouns(_text),
              builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Text(
                      _nouns.join(','),
                      style: const TextStyle(fontSize : 16.0, fontWeight: FontWeight.w500),
                    );
                  } else {
                    return const Text('名詞がありません');
                  }
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        tooltip: _isListening ? '音声認識を停止' : '音声認識を開始',
        child: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyWebView(nouns: _nouns),
                ),
              );
            },
            child: Text('Web View'),
          ),
        ),
      ),
    );
  }
}