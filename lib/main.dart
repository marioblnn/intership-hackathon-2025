import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sentops/Assistant.dart';
import 'package:sentops/CodeGwen.dart';
import 'package:sentops/CodeOllama.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const HomePage(),
        '/assistant': (context) => const Assistant(),
        '/codeGwen': (context) => const CodeWithGwen(),
        '/codeOllama': (context) => const CodeWithOllama(),
      },
      initialRoute: '/',
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openGithub() async {
    const url = 'https://github.com/marioblnn';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  void _showPricingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191A20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Pricing",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            "Everything is currently FREE while we're in development 🚧.\n\nThanks for testing it!",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Nice", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF191A20),
        body: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 0, 0),
                      child: Image.asset(
                        "assets/img/logo.png",
                        width: MediaQuery.of(context).size.width * 0.08,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _openGithub,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          "Docs",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Poppins",
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showPricingDialog(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          "Pricing",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Poppins",
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Sentinel Ops",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w700,
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ),
                    Text(
                      "Right on Your Machine",
                      style: TextStyle(
                        color: const Color(0xFFfE3869),
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w700,
                        fontSize: MediaQuery.of(context).size.width * 0.016,
                      ),
                    ),
                    const Text(
                      "Private AI Code Review Assistant — fast, on-device, and fully private.",
                      style: TextStyle(color: Colors.white, fontFamily: "Poppins"),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.04,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.pushNamed(context, '/assistant');
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.24,
                          height: MediaQuery.of(context).size.height * 0.12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFFfE3869),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Try now",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.w700,
                                    fontSize: MediaQuery.of(context).size.width * 0.02,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_sharp, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.06),
                          child: Lottie.asset(
                            "assets/img/ai.json",
                            frameRate: FrameRate.max,
                            width: MediaQuery.of(context).size.width * 0.18,
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF242424),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.blueGrey,
                                    child: Text("H", style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF333333),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "How can I improve this code?",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) {
                                          return Dialog(
                                            backgroundColor: const Color(0xFF191A20),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 720,
                                                maxHeight: 420,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      "Uploaded document",
                                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: Image.asset(
                                                        "assets/img/code.png",
                                                        height: 240,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    TextButton(
                                                      onPressed: () => Navigator.of(ctx).pop(),
                                                      child: const Text("Close"),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.description_outlined, color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFFfE3869),
                                    child: Icon(Icons.smart_toy, size: 14, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF191A20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "You avoid pulling passwords 🛡️—that’s good. Just ensure the DB file has restricted permissions and don’t print user emails directly in production; return or sanitized-log them instead.",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
