# VoiceInputApp

一款 macOS 菜单栏应用，通过语音识别实现文字输入，支持关键词触发键盘操作。

## 功能特性

- 🎤 **实时语音识别** - 使用 Apple SFSpeechRecognizer，支持中文语音识别
- ⌨️ **智能键盘模拟** - 识别的文字自动输入到当前应用
- 🔑 **灵活热键触发** - 支持 FN 键等多种触发方式
- 📝 **关键词命令** - 语音触发键盘操作（如"结束"→ Enter）
- 🎯 **悬浮窗口反馈** - 实时显示识别结果
- ⚙️ **自定义设置** - 可配置触发键、关键词动作等

## 录制模式

### 长按模式（单键触发）
- 长按 FN 键 0.5 秒开始录音
- 松开按键结束录音并输入文字

### 连续模式（组合键触发）
- 按下组合键开始录音
- 说"结束"关键词停止录音
- 适合长文本连续输入

## 关键词命令

默认支持以下语音命令触发键盘操作：

| 关键词 | 键盘操作 |
|--------|----------|
| 结束 | Enter |
| 上移 | ↑ |
| 下移 | ↓ |
| 左移 | ← |
| 右移 | → |

可在设置中自定义关键词和对应操作。

## 系统要求

- macOS 13.0+
- Swift 5.9

## 安装

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/open-neoflux/VoiceInputApp.git
cd VoiceInputApp

# 使用 Swift Package Manager 构建
swift build

# 或构建发布版本
swift build -c release
```

### 使用 Xcode

```bash
open VoiceInputApp.xcodeproj
```

## 权限设置

应用首次启动时会请求以下权限：

1. **麦克风权限** - 用于语音输入
2. **语音识别权限** - 用于语音转文字
3. **辅助功能权限** - 用于模拟键盘输入

### 辅助功能权限设置

如果键盘输入不工作，请检查辅助功能权限：

1. 打开 **系统设置** → **隐私与安全性** → **辅助功能**
2. 点击左下角锁图标解锁
3. 将 VoiceInputApp 添加到列表并勾选

## 项目结构

```
VoiceInputApp/
├── App/
│   ├── AppDelegate.swift        # 应用生命周期、状态栏、权限处理
│   └── VoiceInputApp.swift      # 应用入口
├── Models/
│   ├── AppSettings.swift        # 应用设置（UserDefaults 持久化）
│   ├── KeywordAction.swift      # 关键词-动作映射模型
│   └── VoiceRecognitionResult.swift
├── ViewModels/
│   ├── MainViewModel.swift      # 主视图模型，服务协调器
│   └── SettingsViewModel.swift  # 设置视图模型
├── Views/
│   ├── MainView.swift           # 主界面
│   ├── SettingsView.swift       # 设置界面
│   └── FloatingTextWindow.swift # 悬浮识别结果窗口
├── Services/
│   ├── SpeechRecognitionService.swift  # 语音识别核心逻辑
│   ├── HotkeyService.swift              # 全局热键监听
│   ├── KeyboardService.swift            # 键盘模拟
│   ├── KeywordProcessor.swift           # 关键词处理
│   └── ClipboardService.swift           # 剪贴板操作
└── Utilities/
    ├── Constants.swift
    └── Extensions.swift
```

## 架构

采用 **MVVM** 架构模式：

- **View** - SwiftUI 视图，绑定 ViewModel 状态
- **ViewModel** - ObservableObject，协调 Service 层
- **Service** - 核心业务逻辑，通过 delegate 协议通信

### 数据流

```
热键触发 → HotkeyService → MainViewModel → SpeechRecognitionService
                                                    ↓
                                            语音识别结果
                                                    ↓
KeywordProcessor ← MainViewModel ← FloatingTextWindow
       ↓
KeyboardService → 输入到目标应用
```

## 自定义设置

### 修改触发键

在设置界面可以自定义触发键，支持：
- 功能键：F1-F12
- 字母键：A-Z
- 数字键：0-9
- 特殊键：Space, Return, Tab, Esc

### 添加关键词动作

在设置界面可以添加自定义关键词和对应的键盘操作。

## 技术栈

- **UI 框架**：SwiftUI
- **语音识别**：Speech framework (SFSpeechRecognizer)
- **音频捕获**：AVFoundation (AVAudioEngine)
- **键盘模拟**：CoreGraphics (CGEvent)
- **热键监听**：AppKit (NSEvent global monitor)
- **持久化**：UserDefaults + Combine

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request。