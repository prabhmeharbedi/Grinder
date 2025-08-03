import SwiftUI
import QuartzCore
import Darwin.Mach

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var isPerformanceGood: Bool = true
    @Published var averageFPS: Double = 60.0
    @Published var isPerformanceOptimal: Bool = true
    
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var fpsHistory: [Double] = []
    private var memoryTimer: Timer?
    
    private init() {}
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard displayLink == nil else { return }
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
        
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateMemoryUsage()
        }
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        memoryTimer?.invalidate()
        memoryTimer = nil
    }
    
    @objc private func displayLinkTick(displayLink: CADisplayLink) {
        frameCount += 1
        
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let currentTime = displayLink.timestamp
        let elapsed = currentTime - lastTimestamp
        
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            
            DispatchQueue.main.async {
                self.currentFPS = fps
                self.fpsHistory.append(fps)
                
                if self.fpsHistory.count > 30 {
                    self.fpsHistory.removeFirst()
                }
                
                self.averageFPS = self.fpsHistory.reduce(0, +) / Double(self.fpsHistory.count)
                self.isPerformanceGood = fps >= 55.0
                self.isPerformanceOptimal = self.averageFPS >= 58.0
                
                if fps < 55.0 {
                    print("⚠️ Low FPS detected: \(String(format: "%.1f", fps))")
                }
            }
            
            frameCount = 0
            lastTimestamp = currentTime
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(info.resident_size) / 1024 / 1024
            
            DispatchQueue.main.async {
                self.memoryUsage = memoryUsageMB
                
                if memoryUsageMB > 50.0 {
                    print("⚠️ High memory usage: \(String(format: "%.1f", memoryUsageMB))MB")
                }
            }
        }
    }
    
    func measureOperation<T>(_ operation: () throws -> T, description: String) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("⏱️ \(description): \(String(format: "%.3f", timeElapsed))s")
        
        if timeElapsed > 0.5 {
            print("⚠️ Slow operation detected: \(description)")
        }
        
        return result
    }
}

// MARK: - Performance Overlay
struct PerformanceOverlay: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                if isVisible {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("FPS: \(String(format: "%.1f", monitor.currentFPS))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(monitor.isPerformanceOptimal ? .green : .red)
                        
                        Text("Mem: \(String(format: "%.1f", monitor.memoryUsage))MB")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .transition(.opacity)
                }
            }
            
            Spacer()
        }
        .padding()
        .onTapGesture(count: 3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible.toggle()
            }
        }
    }
}