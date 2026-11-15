import AVFoundation

/// All sounds are made in code when they are first needed: no sound files.
/// Uses the `.ambient` category, so the silent switch and other apps' audio are respected.
@MainActor
final class SoundEngine {
    var enabled = true {
        didSet { if !enabled { stopPurr() } }
    }

    private let sampleRate: Double = 44_100
    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private var players: [AVAudioPlayerNode] = []
    private let purrPlayer = AVAudioPlayerNode()
    private var nextPlayer = 0
    private var configured = false
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var lastMeow = Date.distantPast
    private var purring = false

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    }

    // MARK: Public sounds

    func click() { play("click") { s in self.tone(&s, .sine, 660, nil, 0.06, 0.07) } }
    func pop() { play("pop") { s in self.tone(&s, .sine, 520, 1250, 0.07, 0.1) } }
    func nom() { play("nom") { s in self.tone(&s, .triangle, 250, 150, 0.1, 0.22) } }
    func plop() { play("plop") { s in self.tone(&s, .sine, 320, 90, 0.2, 0.3) } }
    func jump() { play("jump") { s in self.tone(&s, .triangle, 300, 650, 0.14, 0.12) } }
    func chime() {
        play("chime") { s in
            self.tone(&s, .sine, 988, nil, 0.28, 0.16)
            self.tone(&s, .sine, 1319, nil, 0.4, 0.13, at: 0.09)
        }
    }
    func scoop() {
        play("scoop") { s in
            self.tone(&s, .triangle, 200, 420, 0.12, 0.15)
            self.tone(&s, .sine, 880, nil, 0.18, 0.1, at: 0.1)
        }
    }
    func fanfare() {
        play("fanfare") { s in
            for (i, f) in [523.0, 659, 784, 1047].enumerated() { self.tone(&s, .triangle, f, nil, 0.3, 0.16, at: Double(i) * 0.13) }
        }
    }

    func meow(pitch: Float) {
        guard Date().timeIntervalSince(lastMeow) > 0.7 else { return }
        lastMeow = Date()
        let p = (Double(pitch) * 20).rounded() / 20
        play("meow\(p)") { s in self.meowSamples(&s, pitch: p) }
    }

    func startPurr() {
        guard enabled, !purring, ready() else { return }
        purring = true
        let buffer = cached("purr") { s in self.purrSamples(&s) }
        purrPlayer.volume = 0.9
        purrPlayer.scheduleBuffer(buffer, at: nil, options: [.loops, .interrupts])
        purrPlayer.play()
    }

    func stopPurr() {
        guard purring else { return }
        purring = false
        purrPlayer.stop()
    }

    // MARK: Engine

    private func ready() -> Bool {
        if !configured {
            configured = true
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            for _ in 0..<6 {
                let p = AVAudioPlayerNode()
                engine.attach(p)
                engine.connect(p, to: engine.mainMixerNode, format: format)
                players.append(p)
            }
            engine.attach(purrPlayer)
            engine.connect(purrPlayer, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = 0.7
        }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            do { try engine.start() } catch { return false }
        }
        return true
    }

    private func play(_ key: String, _ make: (inout [Float]) -> Void) {
        guard enabled, ready() else { return }
        let buffer = cached(key, make)
        let p = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        p.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !p.isPlaying { p.play() }
    }

    private func cached(_ key: String, _ make: (inout [Float]) -> Void) -> AVAudioPCMBuffer {
        if let b = cache[key] { return b }
        var samples: [Float] = []
        make(&samples)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(max(samples.count, 1)))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let ch = buffer.floatChannelData?[0] {
            for i in 0..<samples.count { ch[i] = samples[i] }
        }
        cache[key] = buffer
        return buffer
    }

    // MARK: Synthesis

    private enum Wave { case sine, triangle, square, saw }

    private func ensure(_ s: inout [Float], _ count: Int) {
        if s.count < count { s.append(contentsOf: [Float](repeating: 0, count: count - s.count)) }
    }

    private func wave(_ w: Wave, _ phase: Double) -> Double {
        switch w {
        case .sine: return sin(phase)
        case .triangle: return 2 / .pi * asin(sin(phase))
        case .square: return sin(phase) >= 0 ? 0.6 : -0.6
        case .saw:
            let x = phase.truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi)
            return 2 * x - 1
        }
    }

    /// A tone with a quick attack and an exponential fade, like the web version's `tone()`.
    private func tone(_ s: inout [Float], _ w: Wave, _ f0: Double, _ f1: Double?, _ dur: Double, _ vol: Double, at offset: Double = 0) {
        let start = Int(offset * sampleRate), n = Int(dur * sampleRate)
        ensure(&s, start + n)
        var phase = 0.0
        let attack = 0.015
        for i in 0..<n {
            let t = Double(i) / sampleRate
            let f = f1.map { f0 * pow($0 / f0, t / dur) } ?? f0
            phase += 2 * .pi * f / sampleRate
            let env = t < attack ? vol * t / attack : vol * pow(0.0001 / vol, (t - attack) / (dur - attack))
            s[start + i] += Float(wave(w, phase) * env)
        }
    }

    /// A sawtooth through a moving band-pass filter, gliding up and down.
    private func meowSamples(_ s: inout [Float], pitch p: Double) {
        let dur = 0.62, n = Int(dur * sampleRate)
        ensure(&s, n)
        var phase = 0.0
        var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
        var b0 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0, a0 = 1.0
        for i in 0..<n {
            let t = Double(i) / sampleRate
            let f = t < 0.17 ? 430 * p + (780 - 430) * p * t / 0.17 : 780 * p + (520 - 780) * p * min((t - 0.17) / 0.38, 1)
            if i % 16 == 0 {
                let fc = t < 0.2 ? 900 * p + 1000 * p * t / 0.2 : 1900 * p - 900 * p * min((t - 0.2) / 0.35, 1)
                let w0 = 2 * .pi * fc / sampleRate, alpha = sin(w0) / (2 * 3.5)
                b0 = alpha; b2 = -alpha; a0 = 1 + alpha; a1 = -2 * cos(w0); a2 = 1 - alpha
            }
            phase += 2 * .pi * f / sampleRate
            let x = wave(.saw, phase)
            let y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0
            x2 = x1; x1 = x; y2 = y1; y1 = y
            let env: Double
            if t < 0.06 { env = 0.55 * t / 0.06 } else if t < 0.36 { env = 0.55 } else { env = 0.55 * pow(0.0001 / 0.55, (t - 0.36) / 0.26) }
            s[i] = Float(y * env * 2.2)
        }
    }

    /// Low rumble: filtered noise pulsing 24 times a second. One second, looped.
    private func purrSamples(_ s: inout [Float]) {
        let n = Int(sampleRate)
        ensure(&s, n)
        let k = 1 - exp(-2 * .pi * 170 / sampleRate)
        var l1 = 0.0, l2 = 0.0, peak = 0.0
        var raw = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let noise = Double.random(in: -1...1)
            l1 += k * (noise - l1)
            l2 += k * (l1 - l2)
            let t = Double(i) / sampleRate
            let amp = 0.5 + 0.5 * sin(2 * .pi * 24 * t)
            raw[i] = l2 * amp
            peak = max(peak, abs(raw[i]))
        }
        let scale = peak > 0 ? 0.35 / peak : 0
        for i in 0..<n { s[i] = Float(raw[i] * scale) }
    }
}
