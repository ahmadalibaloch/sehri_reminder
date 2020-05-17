import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  FlutterTts flutterTts;

  TextToSpeech() {
    flutterTts = FlutterTts();
  }

  Future speak(text) async {
//    await flutterTts.setVolume(volume);
//    await flutterTts.setSpeechRate(rate);
//    await flutterTts.setPitch(pitch);

    if (text != null) {
      if (text.isNotEmpty) {
        var result = await flutterTts.speak(text);
      }
    }
  }

  Future stop() async {
    var result = await flutterTts.stop();
  }
}
