#!/usr/bin/env swift
//
// apple_stt.swift — On-device speech-to-text using Apple's SFSpeechRecognizer.
//
// Compile:
//   swiftc voice/apple_stt.swift -o voice/apple_stt -framework Speech -framework AVFoundation
//
// Usage:
//   ./voice/apple_stt /path/to/audio.wav
//
// First run will trigger macOS permission prompt for Speech Recognition access.

import Foundation
import Speech

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: apple_stt <audio-file-path>\n", stderr)
    exit(1)
}

let filePath = CommandLine.arguments[1]
let fileURL = URL(fileURLWithPath: filePath)

guard FileManager.default.fileExists(atPath: filePath) else {
    fputs("Error: file not found: \(filePath)\n", stderr)
    exit(1)
}

let semaphore = DispatchSemaphore(value: 0)

// Request authorization
SFSpeechRecognizer.requestAuthorization { status in
    guard status == .authorized else {
        fputs("Error: Speech recognition not authorized (status: \(status.rawValue))\n", stderr)
        fputs("Grant access in System Settings > Privacy & Security > Speech Recognition\n", stderr)
        exit(2)
    }
    semaphore.signal()
}
semaphore.wait()

guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
    fputs("Error: Speech recognizer not available for en-US\n", stderr)
    exit(3)
}

guard recognizer.isAvailable else {
    fputs("Error: Speech recognizer is not available\n", stderr)
    exit(3)
}

let request = SFSpeechURLRecognitionRequest(url: fileURL)
request.shouldReportPartialResults = false

recognizer.recognitionTask(with: request) { result, error in
    if let error = error {
        fputs("Error: \(error.localizedDescription)\n", stderr)
        exit(4)
    }

    guard let result = result, result.isFinal else { return }

    let text = result.bestTranscription.formattedString
    print(text)
    exit(0)
}

// Keep the run loop alive for the async recognition
RunLoop.main.run(until: Date(timeIntervalSinceNow: 30))
fputs("Error: Recognition timed out after 30 seconds\n", stderr)
exit(5)
