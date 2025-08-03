import SwiftUI
import QuartzCore

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var isPerformanceGood: Bool = true
    
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        displayLink?.add(to: .main, forMode: .common)
        
        // Monitor memory usage every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateMemoryUsage()
        }
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func displayLinkTick(displayLink: CADisplayLink) {
        frameCount += 1
        
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let currentTime = displayLink.timestamp
        let elapsed = currentTime - lastTimestamp
        
        // Update FPS every second
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            
            DispatchQueue.main.async {
                self.currentFPS = fps
                self.isPerformanceGood = fps >= 55.0 // Allow 5fps tolerance
                
                if fps < 55.0 {
                    print("⚠️ Low FPS detected: \(String(format: "%.1f", fps))")
                }
            }
            
            frameCount = 0
            lastTimestamp = currentTime
        }
    }
    
    private func updateMemoryUsage() {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
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
    
    // MARK: - Performance Helpers
    
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
    
    func measureAsyncOperation<T>(_ operation: () async throws -> T, description: String) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("⏱️ \(description): \(String(format: "%.3f", timeElapsed))s")
        
        return result
    }
}