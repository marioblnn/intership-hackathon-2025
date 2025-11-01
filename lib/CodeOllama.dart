import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class CodeWithOllama extends StatefulWidget {
  const CodeWithOllama({super.key});

  @override
  State<CodeWithOllama> createState() => _CodeWithOllamaState();
}

class _CodeWithOllamaState extends State<CodeWithOllama> {
  static const String _rolePrompt = """
You are a senior programming/security assistant.
Your ONLY tasks:
1. Review the code the user sends.
2. Identify bugs, logic errors, and missing edge-case handling.
3. Identify security flaws (e.g. injection, unsafe eval, insecure deserialization, path traversal, bad auth, secrets in code).
4. Propose a BETTER / safer version of the code.
5. Explain briefly WHY each change is needed.

OUTPUT FORMAT (FOLLOW EXACTLY):

- Issues found:
<write bullet points here>

- Security risks:
<write bullet points here>

- Improved code:
<WRITE ONLY THE FINAL IMPROVED CODE HERE. NO EXPLANATIONS. NO MARKDOWN. NO TRIPLE BACKTICKS. NO INTRO TEXT. JUST THE CODE.>
""";

  final TextEditingController _codeController = TextEditingController();

  String? _currentFilePath;
  String? _currentFileName;
  bool _isProcessing = false;
  final List<String> _history = [];

  String get _ollamaBaseUrl {
    if (kIsWeb) return 'http://localhost:11434';
    if (Platform.isAndroid) return 'http://10.0.2.2:11434';
    return 'http://localhost:11434';
  }

  Future<String> _callOllama(String code) async {
    final response = await http
        .post(
      Uri.parse("$_ollamaBaseUrl/api/chat"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": "codellama",
        "messages": [
          {"role": "system", "content": _rolePrompt},
          {"role": "user", "content": code}
        ],
        "stream": false
      }),
    )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data["message"]?["content"] ?? "").toString();
    } else {
      throw Exception("Ollama error: ${response.statusCode} ${response.body}");
    }
  }

  Future<void> _improveCode() async {
    final code = _codeController.text;
    if (code.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final reply = await _callOllama(code);

      String issuesText = "", securityText = "", improvedCodeText = reply;
      int issuesIndex = reply.indexOf('- Issues found:');
      int securityIndex = reply.indexOf('- Security risks:');
      int improvedIndex = reply.indexOf('- Improved code:');

      if (improvedIndex != -1) {
        if (issuesIndex != -1 && securityIndex != -1) {
          issuesText = reply.substring(issuesIndex, securityIndex).trim();
        }
        if (securityIndex != -1 && improvedIndex != -1) {
          securityText = reply.substring(securityIndex, improvedIndex).trim();
        }
        improvedCodeText =
            reply.substring(improvedIndex + '- Improved code:'.length).trim();
      }

      // strip code fences if LLM ignored instruction
      if (improvedCodeText.startsWith('```')) {
        int tripleIndex = improvedCodeText.indexOf('\n');
        if (tripleIndex != -1) {
          improvedCodeText = improvedCodeText.substring(tripleIndex + 1);
        }
        int lastTriple = improvedCodeText.lastIndexOf('```');
        if (lastTriple != -1) {
          improvedCodeText = improvedCodeText.substring(0, lastTriple);
        }
        improvedCodeText = improvedCodeText.trim();
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2A2B31),
            title: const Text(
              "LLM Suggested Changes",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (issuesText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        issuesText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (securityText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        securityText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const Text(
                    "- Improved code:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF273239),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      improvedCodeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    if (_history.length >= 20) {
                      _history.removeAt(0);
                    }
                    _history.add(_codeController.text);
                    _codeController.text = improvedCodeText;
                  });
                },
                child: const Text(
                  "Apply Changes",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _undoChange() {
    if (_history.isNotEmpty) {
      setState(() {
        _codeController.text = _history.removeLast();
      });
    }
  }

  Future<void> _openFile() async {
    if (_isProcessing) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      PlatformFile picked = result.files.first;
      String content = '';
      if (!kIsWeb && picked.path != null && picked.path!.isNotEmpty) {
        File file = File(picked.path!);
        try {
          content = await file.readAsString();
        } catch (_) {
          final rawBytes = await file.readAsBytes();
          content = utf8.decode(rawBytes, allowMalformed: true);
        }
        _currentFilePath = picked.path;
      } else if (picked.bytes != null) {
        try {
          content = utf8.decode(picked.bytes!, allowMalformed: true);
        } catch (_) {
          content = String.fromCharCodes(picked.bytes!);
        }
        _currentFilePath = kIsWeb ? picked.name : null;
      }

      setState(() {
        _currentFileName = picked.name;
        _codeController.text = content;
        _history.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open file: $e")),
      );
    }
  }

  Future<void> _newFile() async {
    String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController nameCtrl = TextEditingController();
        return AlertDialog(
          title: const Text("New File"),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: "Enter file name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context, name);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );

    if (fileName == null) {
      return;
    }

    String? directoryPath;
    if (!kIsWeb) {
      directoryPath = await FilePicker.platform.getDirectoryPath();
    }
    String newFilePath;
    if (directoryPath != null) {
      newFilePath = "$directoryPath/$fileName";
    } else {
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        newFilePath = "${dir.path}/$fileName";
      } else {
        newFilePath = fileName;
      }
    }

    setState(() {
      _currentFilePath = newFilePath;
      _currentFileName = fileName;
      _codeController.text = "";
      _history.clear();
    });
  }

  Future<void> _saveFile() async {
    if (_currentFilePath == null || _currentFilePath!.isEmpty) {
      String? savePath;
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File As',
        fileName: _currentFileName ?? 'untitled.txt',
      );

      if (savePath == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Save canceled")));
        return;
      }
      _currentFilePath = savePath;
      if (!kIsWeb) {
        _currentFileName = savePath.split(Platform.pathSeparator).last;
      } else {
        _currentFileName = savePath;
      }
    }

    if (_currentFilePath != null && !kIsWeb) {
      try {
        File file = File(_currentFilePath!);
        await file.writeAsString(_codeController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File saved successfully.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save file: $e")),
        );
      }
    } else if (_currentFilePath != null && kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("File save initiated. Check your downloads."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF191A20);
    const panel = Color(0xFF1F2026);
    const accent = Color(0xFFFE3869);
    const double actionWidth = 160;
    const double actionHeight = 44;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _currentFileName ?? "Untitled",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: "Poppins",
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    onPressed: _saveFile,
                    tooltip: "Save File",
                  ),
                ],
              ),
            ),

            // editor
            Expanded(
              child: Container(
                color: panel,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _codeController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: "Courier",
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: const InputDecoration.collapsed(hintText: ""),
                  cursorColor: Colors.white,
                  maxLines: null,
                  expands: true,
                ),
              ),
            ),

            // bottom bar
            Container(
              color: panel,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Tooltip(
                    message: "New File",
                    child: IconButton(
                      icon: const Icon(
                        Icons.create_new_folder_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _newFile,
                    ),
                  ),
                  Tooltip(
                    message: "Open File",
                    child: IconButton(
                      icon: const Icon(
                        Icons.folder_open_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _openFile,
                    ),
                  ),
                  Tooltip(
                    message: "Undo",
                    child: IconButton(
                      icon: Icon(
                        Icons.undo_rounded,
                        color: _history.isNotEmpty
                            ? Colors.white
                            : Colors.white54,
                      ),
                      onPressed: _history.isNotEmpty ? _undoChange : null,
                    ),
                  ),
                  const Spacer(),
                  // Improve code (fixed size)
                  SizedBox(
                    width: actionWidth,
                    height: actionHeight,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _improveCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text(
                        "Improve code",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ollama code (same size)
                  SizedBox(
                    width: actionWidth,
                    height: actionHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accent.withOpacity(0.55)),
                      ),
                      child: const Center(
                        child: Text(
                          "Ollama code",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
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
