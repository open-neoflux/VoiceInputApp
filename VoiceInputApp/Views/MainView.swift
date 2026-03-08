import SwiftUI

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 16) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(viewModel.isRecording ? Color.red : Color.clear, lineWidth: 2)
                            .scaleEffect(viewModel.isRecording ? 1.5 : 1)
                            .animation(
                                viewModel.isRecording
                                    ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
                                    : .default,
                                value: viewModel.isRecording
                            )
                    )

                Text(viewModel.statusMessage)
                    .font(.headline)
            }

            // Mode indicator
            HStack(spacing: 12) {
                Label("FN", systemImage: "waveform.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("长按说话")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Recognized text
            if !viewModel.recognizedText.isEmpty {
                ScrollView {
                    Text(viewModel.recognizedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 80)
            }

            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording(mode: .holdToTalk)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        Text(viewModel.isRecording ? "停止" : "开始")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(.bordered)

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.bordered)
                .help("退出应用")
            }
        }
        .padding()
        .frame(width: 280)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}