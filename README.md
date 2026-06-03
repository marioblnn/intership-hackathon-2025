#Short Visual Presentation
<img width="1581" height="886" alt="pg1" src="https://github.com/user-attachments/assets/269293b7-76de-4e0e-a0ac-bd820ef1bb72" />
<img width="1575" height="881" alt="pg2" src="https://github.com/user-attachments/assets/313d4d9a-5b77-4a2a-9931-acf3f66ffaa0" />
<img width="1580" height="890" alt="pg3" src="https://github.com/user-attachments/assets/173697bd-fcf1-4b66-a471-4d54b16e7ae1" />


# Sentinel Ops (sentops)

**Private AI Desktop App code review — fully local.**

Sentinel Ops is a Flutter app that connects to [Ollama](https://ollama.com) on your device. Paste or open source files, run **Improve code**, and get structured feedback: bugs, security risks, change rationale, and an improved version you can apply or undo.

## Features

- **Local models** — no cloud API; code stays on your machine
- **Model picker** — choose between assistants from the home screen
- **Lightweight editor** — open, create, and save files; undo up to 20 applied changes
- **Structured review** — issues, security notes, rationale, and commented improved code in one dialog

## Supported models

| UI name | Ollama model | Role |
|--------|--------------|------|
| Code Ollama :7B | `codellama` | General-purpose code generation (chat API) |
| Gwen2.5-code :7B | `qwen2.5-coder:7b` | Deeper reasoning and refactoring (generate API) |

## Prerequisites

1. [Flutter](https://docs.flutter.dev/get-started/install) (SDK `^3.5.4`)
2. [Ollama](https://ollama.com) running locally (default `http://localhost:11434`)
3. Pull the models you plan to use:

```bash
ollama pull codellama
ollama pull qwen2.5-coder:7b
```

## Run the app

```bash
flutter pub get
flutter run
```

Routes: home → **Try now** → Assistant → **Code with this model** → editor.

## Project layout

| File | Purpose |
|------|---------|
| `lib/main.dart` | App shell, home page, navigation |
| `lib/Assistant.dart` | Model selection and descriptions |
| `lib/CodeOllama.dart` | Editor + Code Llama via Ollama `/api/chat` |
| `lib/CodeGwen.dart` | Editor + Qwen2.5 Coder via Ollama `/api/generate` |

