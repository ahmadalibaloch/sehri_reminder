import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  late FlutterTts flutterTts;

  TextToSpeech() {
    flutterTts = FlutterTts();
  }

  speak(text) async {
//    await flutterTts.setVolume(volume);
//    await flutterTts.setSpeechRate(rate);
//    await flutterTts.setPitch(pitch);

    if (text != null) {
      if (text.isNotEmpty) {
        await flutterTts.speak(text);
      }
    }
  }

  stop() async {
    await flutterTts.stop();
  }
}
