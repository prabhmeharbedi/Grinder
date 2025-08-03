import SwiftUI
import Combine

// MARK: - Performance Monitor for 60 FPS Tracking
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var currentFPS: Double = 60.0
    @Published var averageFPS: Double = 60.0
    @Published var isPerformanceOptimal: Bool = true
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsHistory: [Double] = []
    private let maxHistoryCount = 60 // Track last 60 frames
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func displayLinkDidFire(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        let currentTimestamp = displayLink.timestamp
        let deltaTime = currentTimestamp - lastTimestamp
        
        if deltaTime > 0 {
            let fps = 1.0 / deltaTime
            
            DispatchQueue.main.async {
                self.updateFPS(fps)
            }
        }
        
        lastTimestamp = currentTimestamp
        frameCount += 1
    }
    
    private func updateFPS(_ fps: Double) {
        currentFPS = fps
        
        // Add to history
        fpsHistory.append(fps)
        if fpsHistory.count > maxHistoryCount {
            fpsHistory.removeFirst()
        }
        
        // Calculate average
        averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)
        
        // Determine if performance is optimal (above 55 FPS average)
        isPerformanceOptimal = averageFPS >= 55.0
        
        // Log performance issues
        if !isPerformanceOptimal {
            print("⚠️ Performance Warning: Average FPS: \(String(format: "%.1f", averageFPS))")
        }
    }
    
    func getPerformanceReport() -> String {
        return """
        Current FPS: \(String(format: "%.1f", currentFPS))
        Average FPS: \(String(format: "%.1f", averageFPS))
        Performance Status: \(isPerformanceOptimal ? "Optimal" : "Needs Optimization")
        Frame Count: \(frameCount)
        """
    }
}

// MARK: - Performance Overlay View (Debug Only)
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
                        
                        Text("Avg: \(String(format: "%.1f", monitor.averageFPS))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.7))
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

// MARK: - Performance Optimized List View
struct OptimizedListView<Content: View>: View {
    let content: () -> Content
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                content()
            }
        }
        .scrollIndicators(.hidden)
        .clipped()
    }
}

// MARK: - Performance Optimized Animation Modifiers
extension View {
    func optimizedAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.animation(animation?.speed(1.2), value: value) // Slightly faster animations for responsiveness
    }
    
    func smoothTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 1.05))
        ))
    }
    
    func performanceOptimized() -> some View {
        self
            .drawingGroup() // Rasterize complex views
            .clipped() // Prevent overdraw
    }
}

// MARK: - Memory Efficient Image View
struct OptimizedImageView: View {
    let systemName: String
    let color: Color
    let size: CGFloat
    
    @State private var isLoaded = false
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundColor(color)
            .opacity(isLoaded ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isLoaded = true
                }
            }
    }
}

// MARK: - Optimized Progress View
struct OptimizedProgressView: View {
    let value: Double
    let color: Color
    
    @State private var animatedValue: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(animatedValue), height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.5), value: animatedValue)
            }
        }
        .frame(height: 8)
        .onAppear {
            animatedValue = value
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - Optimized Circular Progress View
struct OptimizedCircularProgress: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(animatedProgress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newProgress
            }
        }
    }
}