
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const NovaAI());
}

class NovaAI extends StatelessWidget {
  const NovaAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const NovaHome(),
    );
  }
}

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});

  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  final TextEditingController input = TextEditingController();

  bool listening = false;
  bool speechReady = false;
  bool hindi = true;

  String status = 'NOVA READY';
  String lastText = 'नमस्ते! मैं NOVA हूँ।';

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    setupVoice();
  }

  Future<void> setupVoice() async {
    speechReady = await speech.initialize(
      onStatus: (s) {
        if ((s == 'notListening' || s == 'done') && mounted) {
          setState(() {
            listening = false;
            status = 'NOVA READY';
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            listening = false;
            status = 'VOICE ERROR';
          });
        }
      },
    );

    await setLanguage();
    if (mounted) setState(() {});
  }

  Future<void> setLanguage() async {
    await tts.setLanguage(hindi ? 'hi-IN' : 'en-US');
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }

  void changeLanguage() async {
    if (listening) await speech.stop();
    setState(() {
      listening = false;
      hindi = !hindi;
      status = 'NOVA READY';
      lastText = hindi ? 'भाषा हिंदी कर दी गई।' : 'Language changed to English.';
    });
    await setLanguage();
    speak(lastText);
  }

  Future<void> toggleMic() async {
    if (!speechReady) await setupVoice();

    if (!speechReady) {
      setState(() => status = 'VOICE NOT AVAILABLE');
      return;
    }

    if (listening) {
      await speech.stop();
      setState(() {
        listening = false;
        status = 'NOVA READY';
      });
      return;
    }

    await tts.stop();
    setState(() {
      listening = true;
      status = hindi ? 'सुन रही हूँ...' : 'LISTENING...';
    });

    await speech.listen(
      localeId: hindi ? 'hi-IN' : 'en-US',
      onResult: (result) {
        if (!mounted) return;
        setState(() => lastText = result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          respond(result.recognizedWords);
        }
      },
    );
  }

  String getTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm";
  }

  String getDate() {
    final now = DateTime.now();
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const hindiDays = [
      'रविवार', 'सोमवार', 'मंगलवार', 'बुधवार',
      'गुरुवार', 'शुक्रवार', 'शनिवार'
    ];
    const hindiMonths = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];

    if (hindi) {
      return '${hindiDays[now.weekday % 7]}, ${now.day} '
          '${hindiMonths[now.month - 1]} ${now.year}';
    }
    return '${days[now.weekday % 7]}, ${now.day} '
        '${months[now.month - 1]} ${now.year}';
  }

  String? calculate(String text) {
    final normalized = text
        .replaceAll('×', '*')
        .replaceAll('x', '*')
        .replaceAll('÷', '/')
        .replaceAll('plus', '+')
        .replaceAll('minus', '-')
        .replaceAll('multiply', '*')
        .replaceAll('into', '*')
        .replaceAll('divided by', '/');

    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(normalized);

    if (match == null) return null;

    final a = double.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = double.parse(match.group(3)!);

    double result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        if (b == 0) {
          return hindi ? 'शून्य से भाग नहीं कर सकते।' : 'Cannot divide by zero.';
        }
        result = a / b;
        break;
      default:
        return null;
    }

    final formatted = result == result.roundToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(2);

    return hindi ? 'उत्तर है $formatted' : 'The answer is $formatted';
  }

  void respond(String message) {
    final text = message.toLowerCase().trim();
    String answer;

    final mathAnswer = calculate(text);

    if (mathAnswer != null) {
      answer = mathAnswer;
    } else if (text.contains('time') || text.contains('समय') ||
        text.contains('कितने बजे')) {
      answer = hindi ? 'अभी समय है ${getTime()}' : 'The time is ${getTime()}';
    } else if (text.contains('date') || text.contains('तारीख') ||
        text.contains('today') || text.contains('दिन')) {
      answer = hindi ? 'आज ${getDate()} है।' : 'Today is ${getDate()}.';
    } else if (text.contains('hello') || text.contains('hi') ||
        text.contains('नमस्ते') || text.contains('हेलो')) {
      answer = hindi
          ? 'नमस्ते! मैं NOVA हूँ। बताइए, मैं क्या मदद करूँ?'
          : 'Hello! I am NOVA. How can I help you?';
    } else if (text.contains('your name') || text.contains('नाम') ||
        text.contains('who are you')) {
      answer = hindi ? 'मेरा नाम NOVA AI है।' : 'My name is NOVA AI.';
    } else if (text.contains('how are you') || text.contains('कैसी हो') ||
        text.contains('कैसे हो')) {
      answer = hindi ? 'मैं तैयार हूँ! बताइए, क्या करना है?'
          : 'I am ready to help!';
    } else if (text.contains('thank') || text.contains('धन्यवाद')) {
      answer = hindi ? 'आपका स्वागत है!' : 'You are welcome!';
    } else if (text.contains('help') || text.contains('मदद')) {
      answer = hindi
          ? 'आप समय, तारीख, आसान गणित या मुझसे बातचीत कर सकते हैं।'
          : 'Ask me about time, date, simple math or chat.';
    } else {
      answer = hindi
          ? 'मैंने सुना: $message। समय, तारीख या गणित पूछिए।'
          : 'I heard: $message. Ask me about time, date or math.';
    }

    setState(() {
      lastText = answer;
      status = 'NOVA RESPONDING';
      listening = false;
    });

    speak(answer);
  }

  void sendMessage() {
    final message = input.text.trim();
    if (message.isEmpty) return;
    input.clear();
    respond(message);
  }

  @override
  void dispose() {
    controller.dispose();
    input.dispose();
    speech.stop();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05090F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),
            const Text(
              'N O V A',
              style: TextStyle(
                color: Color(0xFFBDEBFF),
                fontSize: 26,
                letterSpacing: 9,
                fontWeight: FontWeight.w300,
              ),
            ),
            const Text(
              'ARTIFICIAL INTELLIGENCE',
              style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 4),
            ),
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: changeLanguage,
                child: Text(
                  hindi ? 'हिंदी | EN' : 'EN | हिंदी',
                  style: const TextStyle(color: Color(0xFFBDEBFF)),
                ),
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(
                size: const Size(310, 310),
                painter: OrbPainter(controller.value),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              status,
              style: const TextStyle(color: Color(0xFF9DDFFF), letterSpacing: 4, fontSize: 11),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                lastText,
                textAlign: TextAlign.center,
                maxLines: 4,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: toggleMic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: listening ? 86 : 74,
                height: listening ? 86 : 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C1923),
                  border: Border.all(color: const Color(0xFF9DDFFF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8EDCFF).withOpacity(listening ? 0.30 : 0.10),
                      blurRadius: listening ? 30 : 14,
                    ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: const Color(0xFFBDEBFF),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('TAP TO SPEAK', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 3)),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      onSubmitted: (_) => sendMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: hindi ? 'NOVA से बात करें...' : 'Message NOVA...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF101822),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    color: const Color(0xFFBDEBFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrbPainter extends CustomPainter {
  final double progress;
  OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;

    final glow = Paint()
      ..color = const Color(0xFF8EDCFF).withOpacity(0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    canvas.drawCircle(center, radius * 1.5, glow);

    final ring = Paint()
      ..color = const Color(0xFFB5E8FF).withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawCircle(center, radius * 1.23, ring);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    const count = 900;

    for (int i = 0; i < count; i++) {
      final y = 1 - (2 * (i + 0.5) / count);
      final r = math.sqrt(1 - y * y);
      final theta = i * 2.399963 + progress * 2 * math.pi;

      final x = math.cos(theta) * r;
      final z = math.sin(theta) * r;
      const tilt = 0.35;

      final rotatedY = y * math.cos(tilt) - z * math.sin(tilt);
      final rotatedZ = y * math.sin(tilt) + z * math.cos(tilt);
      final depth = (rotatedZ + 1) / 2;

      final px = center.dx + x * radius;
      final py = center.dy + rotatedY * radius;

      final alpha = (0.12 + depth * 0.38).clamp(0.0, 1.0);
      final dotSize = 0.5 + depth * 1.15;

      dotPaint.color = Color.fromRGBO(170, 220, 245, alpha);
      canvas.drawCircle(Offset(px, py), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
