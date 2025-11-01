import 'package:flutter/material.dart';

class Assistant extends StatefulWidget {
  const Assistant({super.key});

  @override
  State<Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<Assistant> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  static const _accent = Color(0xFFFE3869);
  static const _bg = Color(0xFF191A20);

  final _models = const [
    ("Code Ollama :7B", "General-purpose code generation"),
    ("Gwen2.5-code :7B", "Code assistant with deeper reasoning"),
    ("Gwen2.5-code :14B", "Model currently offline"),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Assistant models",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Poppins",
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_moon_outlined, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Local env",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // subtitle
            const Padding(
              padding: EdgeInsets.fromLTRB(58, 6, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pick a model and start coding.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // model pills
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _models.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  final (title, _) = _models[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _onSelect(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected
                            ? Border.all(color: Colors.white.withOpacity(0.1))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.memory_rounded : Icons.memory_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontFamily: "Poppins",
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _selectedIndex = page),
                children: [
                  _ModelDescription(
                    title: "Code Ollama :7B",
                    subtitle: "General-purpose code generation",
                    description:
                    "Optimized for Dart, Flutter, JS/TS and Python. Use this when you want clean, readable code and short reasoning.",
                    onCode: () => Navigator.pushNamed(context, '/codeOllama'),
                  ),
                  _ModelDescription(
                    title: "Gwen2.5-code :7B",
                    subtitle: "Code assistant with deeper reasoning",
                    description:
                    "Better at step-by-step explanations and refactoring. Good for fixing existing code and adding docs.",
                    onCode: () => Navigator.pushNamed(context, '/codeGwen'),
                  ),
                  const _ModelDescription(
                    title: "Gwen2.5-code :14B",
                    subtitle: "Model currently offline",
                    description: "",
                    isUnavailable: true,
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

class _ModelDescription extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final bool isUnavailable;
  final VoidCallback? onCode;

  const _ModelDescription({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    this.isUnavailable = false,
    this.onCode,
  });

  @override
  State<_ModelDescription> createState() => _ModelDescriptionState();
}

class _ModelDescriptionState extends State<_ModelDescription> {
  final _scrollController = ScrollController();

  static const _card = Color(0xFF1F2026);
  static const _accent = Color(0xFFFE3869);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Card(
        color: _card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isUnavailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "Unavailable",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (widget.description.isNotEmpty)
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 22),

                if (!widget.isUnavailable)
                  ElevatedButton.icon(
                    onPressed: widget.onCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.code_rounded, size: 18),
                    label: const Text("Code with this model"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
