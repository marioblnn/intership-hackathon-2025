import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 added
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform, File;

class OllamaCode extends StatefulWidget {
  const OllamaCode({super.key});

  @override
  State<OllamaCode> createState() => _OllamaCodeState();
}

class _OllamaCodeState extends State<OllamaCode> {
  static const String _rolePrompt = """
You are a senior programming/security assistant.
Your ONLY tasks:
1. Review the code the user sends.
2. Identify bugs, logic errors, and missing edge-case handling.
3. Identify security flaws (e.g. injection, unsafe eval, insecure deserialization, path traversal, bad auth, secrets in code).
4. Propose a BETTER / safer version of the code.
5. Explain briefly WHY each change is needed.
If the user asks for anything unrelated to code review, say: "I only do secure code review and improvements."
Output in this structure:
- Issues found:
- Security risks:
- Improved code:
""";

  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "text": "Hi! Send me code or a question and I’ll assist you."
    },
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _useContext = true;

  String get _ollamaBaseUrl {
    if (kIsWeb) return 'http://localhost:11434';
    if (Platform.isAndroid) return 'http://10.0.2.2:11434';
    return 'http://localhost:11434';
  }

  List<Map<String, String>> _buildOllamaMessages() {
    if (!_useContext) {
      final lastUser = _messages.lastWhere(
            (m) => m["role"] == "user",
        orElse: () => {"role": "user", "text": ""},
      );
      return [
        {"role": "system", "content": _rolePrompt},
        {"role": "user", "content": lastUser["text"] ?? ""},
      ];
    }

    const maxHistory = 12;
    final recent = _messages.length > maxHistory
        ? _messages.sublist(_messages.length - maxHistory)
        : _messages;

    return [
      {"role": "system", "content": _rolePrompt},
      ...recent.map((m) {
        return {
          "role": m["role"] == "user" ? "user" : "assistant",
          "content": m["text"] ?? "",
        };
      }),
    ];
  }

  Future<String> _callOllamaChat() async {
    final resp = await http
        .post(
      Uri.parse('$_ollamaBaseUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": "codellama",
        "messages": _buildOllamaMessages(),
        "stream": false,
      }),
    )
        .timeout(const Duration(seconds: 120));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data["message"]?["content"] ?? "").toString();
    } else {
      throw Exception('Ollama error: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _callOllamaChat();
      if (!mounted) return;
      setState(() {
        _messages.add({"role": "assistant", "text": reply});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": "Couldn't reach Ollama: $e"
        });
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickAndAnalyzeFile() async {
    if (_isSending) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.single;
      String content = '';

      if (!kIsWeb && picked.path != null && picked.path!.isNotEmpty) {
        final file = File(picked.path!);
        try {
          content = await file.readAsString();
        } catch (_) {
          final raw = await file.readAsBytes();
          content = utf8.decode(raw, allowMalformed: true);
        }
      } else if (picked.bytes != null && picked.bytes!.isNotEmpty) {
        try {
          content = utf8.decode(picked.bytes!, allowMalformed: true);
        } catch (_) {
          content = String.fromCharCodes(picked.bytes!);
        }
      }

      if (content.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _messages.add({
            "role": "assistant",
            "text":
            "I could pick **${picked.name}** but couldn’t read text from it (maybe it’s binary?)."
          });
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _messages.add({
          "role": "user",
          "text": "File: ${picked.name}\n\n$content"
        });
        _isSending = true;
      });
      _scrollToBottom();

      final reply = await _callOllamaChat();
      if (!mounted) return;
      setState(() {
        _messages.add({"role": "assistant", "text": reply});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "role": "assistant",
          "text": "File pick/read failed: $e"
        });
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyMessage(String? text) {
    if (text == null || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF191A20),
      body: SafeArea(
        child: Column(
          children: [
            // header
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Ollama-Code - 7B parameters",
                  style: TextStyle(
                    fontFamily: "Poppins",
                    color: Colors.white,
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // chat history
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  final text = msg["text"] ?? "";
                  return Align(
                    alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints:
                          BoxConstraints(maxWidth: size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFFFE3869)
                                : const Color(0xFF1F2026),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                              bottomRight: isUser
                                  ? Radius.zero
                                  : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _copyMessage(text),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // input bar
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2026),
                border: Border(
                  top: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // text field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: "Paste code to review…",
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF2A2B31),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // file button
                  InkWell(
                    onTap: _pickAndAnalyzeFile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.folder_open_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // context toggle
                  InkWell(
                    onTap: () {
                      setState(() {
                        _useContext = !_useContext;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _useContext
                            ? const Color(0xFF4CAF50).withOpacity(0.18)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _useContext
                              ? const Color(0xFF4CAF50)
                              : Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.memory_rounded,
                        size: 20,
                        color: _useContext
                            ? const Color(0xFF4CAF50)
                            : Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // send
                  InkWell(
                    onTap: _isSending ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isSending
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFFFE3869),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
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
