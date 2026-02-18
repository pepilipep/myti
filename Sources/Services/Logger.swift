import Foundation

final class Logger {
    static let shared = Logger()

    private let maxSize = 1_000_000  // 1 MB
    private let keepLines = 500
    private var logPath: String = ""

    private init() {
        #if DEBUG
        let appName = "myti-dev"
        #else
        let appName = "myti"
        #endif
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent(appName)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        logPath = dir.appendingPathComponent("myti.log").path

        // Rotate if too large
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logPath),
           let size = attrs[.size] as? Int, size > maxSize {
            if let content = try? String(contentsOfFile: logPath, encoding: .utf8) {
                let lines = content.components(separatedBy: "\n")
                let kept = lines.suffix(keepLines).joined(separator: "\n") + "\n"
                try? kept.write(toFile: logPath, atomically: true, encoding: .utf8)
            }
        }
    }

    private func write(level: String, msg: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let line = "[\(formatter.string(from: Date()))] [\(level)] \(msg)\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let handle = FileHandle(forWritingAtPath: logPath) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }

    func info(_ msg: String) {
        self.write(level: "INFO", msg: msg)
    }

    func warn(_ msg: String) {
        self.write(level: "WARN", msg: msg)
    }

    func error(_ msg: String, error: Error? = nil) {
        let suffix = error.map { " — \($0.localizedDescription)" } ?? ""
        self.write(level: "ERROR", msg: msg + suffix)
    }
}
