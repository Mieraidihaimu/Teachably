import AVFAudio
import Foundation
import SwiftUI
import TeachablyCore

struct StoryRecording: Identifiable {
    let url: URL
    let date: Date
    var id: URL { url }
}

final class StoryAudioRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    @Published private(set) var recordings: [StoryRecording] = []
    @Published private(set) var recordingSince: Date?
    @Published private(set) var playingID: URL?
    @Published private(set) var isRequestingPermission = false
    @Published var errorMessage: String?
    private let folder: URL
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var permissionRequest: UUID?

    init(storyID: String) {
        folder = Self.recordingFolder(for: storyID)
        super.init()
        do { try loadRecordings() }
        catch { errorMessage = L10n.string("Saved recordings couldn’t be opened.") }
    }

    static func hasRecordings(for storyID: String) -> Bool {
        let files = try? recordingFiles(in: recordingFolder(for: storyID))
        return files?.isEmpty == false
    }

    private static func recordingFolder(for storyID: String) -> URL {
        var directory = URL.applicationSupportDirectory.appending(path: "ShowAndTellRecordings", directoryHint: .isDirectory)
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["TEACHABLY_TEST_SUITE"] {
            directory.append(path: suite, directoryHint: .isDirectory)
        }
        #endif
        return directory.appending(path: storyID, directoryHint: .isDirectory)
    }

    func startRecording() async {
        guard recorder == nil, permissionRequest == nil else { return }
        stopPlayback()
        errorMessage = nil
        let request = UUID()
        permissionRequest = request
        isRequestingPermission = true
        let allowed = await AVAudioApplication.requestRecordPermission()
        guard permissionRequest == request else { return }
        permissionRequest = nil
        isRequestingPermission = false
        guard allowed else {
            errorMessage = L10n.string("Allow microphone access for Teachably in Settings to record your story.")
            return
        }
        let pending = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).m4a")
        let session = AVAudioSession.sharedInstance()
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let audio = try AVAudioRecorder(url: pending, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            audio.delegate = self
            guard audio.record() else { throw CocoaError(.fileWriteUnknown) }
            recorder = audio
            recordingSince = .now
        } catch {
            try? FileManager.default.removeItem(at: pending)
            releaseAudioSession()
            errorMessage = L10n.string("Recording couldn’t start. Check that a microphone is available and try again.")
        }
    }

    func finishRecording() {
        guard let recorder else { return }
        recorder.delegate = nil
        recorder.stop()
        saveRecording(at: recorder.url)
    }

    private func saveRecording(at url: URL) {
        recorder = nil
        recordingSince = nil
        releaseAudioSession()
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            guard audio.duration > 0 else { throw CocoaError(.fileReadCorruptFile) }
            try FileManager.default.moveItem(at: url, to: folder.appending(path: url.lastPathComponent))
            try loadRecordings()
        } catch {
            errorMessage = L10n.string("This recording couldn’t be saved. Please try again.")
        }
    }

    func togglePlayback(_ recording: StoryRecording) {
        guard recorder == nil, !isRequestingPermission else { return }
        let wasPlaying = playingID == recording.id
        stopPlayback()
        guard !wasPlaying else { return }
        errorMessage = nil
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let audio = try AVAudioPlayer(contentsOf: recording.url)
            audio.delegate = self
            guard audio.play() else { throw CocoaError(.fileReadUnknown) }
            player = audio
            playingID = recording.id
        } catch {
            releaseAudioSession()
            errorMessage = L10n.string("This recording couldn’t be played.")
        }
    }

    func delete(_ recording: StoryRecording) {
        if playingID == recording.id { stopPlayback() }
        do {
            try FileManager.default.removeItem(at: recording.url)
            recordings.removeAll { $0.id == recording.id }
        } catch {
            errorMessage = L10n.string("This recording couldn’t be deleted.")
        }
    }

    func stopAudio() {
        permissionRequest = nil
        isRequestingPermission = false
        finishRecording()
        stopPlayback()
    }

    private func stopPlayback() {
        guard let player else { return }
        player.delegate = nil
        player.stop()
        self.player = nil
        playingID = nil
        releaseAudioSession()
    }

    private func loadRecordings() throws {
        recordings = try Self.recordingFiles(in: folder).map { url in
            let date = try url.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
            return StoryRecording(url: url, date: date)
        }.sorted { $0.date > $1.date }
    }

    private static func recordingFiles(in folder: URL) throws -> [URL] {
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(at: folder,
                includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            return []
        }
        return files.filter { $0.pathExtension == "m4a" }
    }

    private func releaseAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let playback = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let player = self.player, ObjectIdentifier(player) == playback else { return }
            stopPlayback()
            if !flag { errorMessage = L10n.string("This recording couldn’t be played.") }
        }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let url = recorder.url
        Task { @MainActor [weak self] in
            guard let self, self.recorder?.url == url else { return }
            if flag {
                saveRecording(at: url)
            } else {
                discardRecording(at: url)
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        let url = recorder.url
        Task { @MainActor [weak self] in
            guard let self, self.recorder?.url == url else { return }
            discardRecording(at: url)
        }
    }

    private func discardRecording(at url: URL) {
        recorder?.delegate = nil
        recorder?.stop()
        recorder = nil
        recordingSince = nil
        try? FileManager.default.removeItem(at: url)
        releaseAudioSession()
        errorMessage = L10n.string("This recording couldn’t be saved. Please try again.")
    }
}
