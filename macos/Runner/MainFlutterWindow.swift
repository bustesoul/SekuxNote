import Cocoa
import AVFoundation
import FlutterMacOS

/// Export one-minute M4A files with AVFoundation. This stays inside the app
/// sandbox and avoids shipping a separate transcoder executable.
final class AudioChunkerPlugin: NSObject, FlutterPlugin {
  private var activeExport: AVAssetExportSession?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.sekuxnote/audio_chunker",
      binaryMessenger: registrar.messenger
    )
    registrar.addMethodCallDelegate(AudioChunkerPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "split",
          let arguments = call.arguments as? [String: Any],
          let inputPath = arguments["inputPath"] as? String,
          let outputDirectory = arguments["outputDirectory"] as? String,
          let seconds = arguments["chunkDurationSeconds"] as? Int,
          seconds > 0 else {
      result(FlutterError(code: "invalid_arguments", message: "Invalid audio split request.", details: nil))
      return
    }

    let asset = AVURLAsset(url: URL(fileURLWithPath: inputPath))
    asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
      DispatchQueue.main.async {
        guard let self else { return }
        var error: NSError?
        guard asset.statusOfValue(forKey: "duration", error: &error) == .loaded else {
          result(FlutterError(code: "asset_load_failed", message: error?.localizedDescription ?? "Unable to read audio duration.", details: nil))
          return
        }
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration.isFinite, duration > 0 else {
          result(FlutterError(code: "invalid_duration", message: "Audio duration is invalid.", details: nil))
          return
        }
        self.export(
          asset: asset,
          duration: duration,
          seconds: Double(seconds),
          outputDirectory: URL(fileURLWithPath: outputDirectory),
          index: 0,
          completed: [],
          result: result
        )
      }
    }
  }

  private func export(
    asset: AVAsset,
    duration: Double,
    seconds: Double,
    outputDirectory: URL,
    index: Int,
    completed: [String],
    result: @escaping FlutterResult
  ) {
    let start = Double(index) * seconds
    guard start < duration else {
      activeExport = nil
      result(completed)
      return
    }
    guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      result(FlutterError(code: "export_unavailable", message: "Unable to prepare audio export.", details: nil))
      return
    }
    let output = outputDirectory.appendingPathComponent(String(format: "chunk_%03d.m4a", index + 1))
    try? FileManager.default.removeItem(at: output)
    export.outputURL = output
    export.outputFileType = .m4a
    export.timeRange = CMTimeRange(
      start: CMTime(seconds: start, preferredTimescale: 600),
      duration: CMTime(seconds: min(seconds, duration - start), preferredTimescale: 600)
    )
    activeExport = export
    export.exportAsynchronously { [weak self] in
      DispatchQueue.main.async {
        guard let self else { return }
        guard export.status == .completed else {
          self.activeExport = nil
          result(FlutterError(
            code: "export_failed",
            message: export.error?.localizedDescription ?? "Audio export failed.",
            details: nil
          ))
          return
        }
        self.export(
          asset: asset,
          duration: duration,
          seconds: seconds,
          outputDirectory: outputDirectory,
          index: index + 1,
          completed: completed + [output.path],
          result: result
        )
      }
    }
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    AudioChunkerPlugin.register(
      with: flutterViewController.registrar(forPlugin: "AudioChunkerPlugin")
    )

    super.awakeFromNib()
  }
}
