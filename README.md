# Jump Chat (ChatGPTClone)

Jump Chat is an iOS SwiftUI application that lets you chat with OpenAI’s GPT models using text or voice. Conversations are persisted locally via Core Data so you can revisit past chats—and resume context when you come back later.

---

## 🎯 Features

- **Text Chat**  
  Send free-form messages and see GPT responses streamed in real time, with Markdown rendering and code-block support.

- **Voice Chat**  
  Press and speak to transcribe audio via OpenAI Whisper → send the transcript to GPT → play back the TTS response. Includes a “yarn” animation that pulses & spins faster when you speak.

- **Conversation Persistence**  
  Each conversation is saved in Core Data (with full message history and rich formatting). Browse history, delete or start new chats, and pick up where you left off—with context automatically applied to the next API call.

- **Custom Voices**  
  Choose from multiple TTS voices in **Settings**. Selections are stored via a simple `@Preference` wrapper over `UserDefaults`.

- **Copy & Play Buttons**  
  Copy any AI response to the clipboard or replay it as speech with a single tap.

- **UI Polishes**  
  - Shimmering “Thinking…” indicator while GPT is generating.  
  - Chat bubbles with adjustable padding and light/dark support.  
  - Toolbar buttons for **History** and **Settings**.  
  - Network- and permission-aware error states and toasts.

---

## 🛠 Requirements

- **iOS:** 17.0+  
- **Xcode:** 15  
- **Swift:** 5.9  

---

## 🚀 Getting Started

1. **Clone the repo**  
   ```bash
   git clone https://github.com/your-username/ChatGPTClone.git
   cd ChatGPTClone

2. **Add your OpenAI API Key**
Create a file Secrets.xcconfig in the project root (not committed to Git):

OPENAI_API_KEY = sk-YOUR_REAL_KEY

## Project Structure

```text
ChatGPTClone/
├─ AppDelegate.swift
├─ Assets.xcassets
├─ Info.plist
├─ Secrets.xcconfig         ← your local API key
├─ Sources/
│   ├─ Views/
│   │   ├─ ConversationHomeView.swift
│   │   ├─ VoiceConversationView.swift
│   │   ├─ MessageRowView.swift
│   │   ├─ ChatBubble.swift
│   │   └─ SettingsView.swift
│   ├─ ViewModels/
│   │   ├─ ConversationHomeViewModel.swift
│   │   ├─ ConversationHistoryViewModel.swift
│   │   └─ VoiceConversationViewModel.swift
│   ├─ CoreData/
│   │   ├─ PersistenceController.swift
│   │   ├─ ConversationEntity+CoreDataClass.swift
│   │   └─ MessageEntity+CoreDataClass.swift
│   ├─ Models/
│   │   ├─ MessageRow.swift
│   │   ├─ ParserResult.swift
│   │   └─ VoiceType.swift
│   ├─ Services/
│   │   └─ OpenAIAPI.swift
│   └─ Utils/
│       ├─ HapticsManager.swift
│       ├─ PlistHelper.swift
│       └─ ShimmerModifier.swift
└─ README.md
