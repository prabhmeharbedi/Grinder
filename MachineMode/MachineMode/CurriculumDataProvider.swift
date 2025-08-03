import Foundation

// MARK: - Data Structures

struct DSAProblemData {
    let name: String
    let leetcodeNumber: String?
    let difficulty: String
    let goal: String?
    let weekTheme: String
}

struct SystemDesignTopicData {
    let name: String
    let description: String?
    let taskType: TaskType
    let videoReference: String?
    let weekTheme: String
}

enum TaskType {
    case video(String)
    case diagram(String)
    case exercise(String)
    case bonus(String)
}

// MARK: - Curriculum Data Provider

struct CurriculumDataProvider {
    
    // Week-based organization matching sssss.md structure
    static let weeklyThemes = [
        1: "FOUNDATIONS",
        2: "SLIDING WINDOWS & HASH MAPS",
        3: "STACKS, LINKED LISTS & RATE LIMITING",
        4: "BINARY SEARCH & RECURSION",
        5: "BACKTRACKING & TREES",
        6: "TREES ADVANCED & WHATSAPP",
        7: "GRAPHS I & YOUTUBE",
        8: "GRAPHS II & UBER",
        9: "DYNAMIC PROGRAMMING I & TWITTER",
        10: "DYNAMIC PROGRAMMING II & NOTIFICATIONS",
        11: "GREEDY & SYSTEM DESIGN REVISION",
        12: "MIXED REVISION & MOCK PREP",
        13: "MOCK WEEK 1 - PRESSURE TESTING",
        14: "MOCK WEEK 2 - FINAL PREPARATION"
    ]
    
    static func getWeekTheme(for day: Int) -> String {
        let weekNumber = ((day - 1) / 7) + 1
        return weeklyThemes[weekNumber] ?? "UNKNOWN WEEK"
    }
    
    static func getDSAProblems(for day: Int) -> [DSAProblemData] {
        let weekTheme = getWeekTheme(for: day)
        
        switch day {
        case 1:
            return [
                DSAProblemData(name: "Build Array from Permutation", leetcodeNumber: "1920", difficulty: "Easy", goal: "Focus on problem patterns, not just solutions. Write notes for each.", weekTheme: weekTheme),
                DSAProblemData(name: "Running Sum of 1d Array", leetcodeNumber: "1480", difficulty: "Easy", goal: "Focus on problem patterns, not just solutions. Write notes for each.", weekTheme: weekTheme),
                DSAProblemData(name: "Find Numbers with Even Number of Digits", leetcodeNumber: "1295", difficulty: "Easy", goal: "Focus on problem patterns, not just solutions. Write notes for each.", weekTheme: weekTheme),
                DSAProblemData(name: "How Many Numbers Are Smaller Than the Current Number", leetcodeNumber: "1365", difficulty: "Easy", goal: "Focus on problem patterns, not just solutions. Write notes for each.", weekTheme: weekTheme),
                DSAProblemData(name: "Merge Sorted Array", leetcodeNumber: "88", difficulty: "Easy", goal: "Focus on problem patterns, not just solutions. Write notes for each.", weekTheme: weekTheme)
            ]
        case 2:
            return [
                DSAProblemData(name: "Move Zeroes", leetcodeNumber: "283", difficulty: "Easy", goal: "Practice pointer movement. Visualize pointer positions.", weekTheme: weekTheme),
                DSAProblemData(name: "Two Sum II - Input Array Is Sorted", leetcodeNumber: "167", difficulty: "Easy", goal: "Practice pointer movement. Visualize pointer positions.", weekTheme: weekTheme),
                DSAProblemData(name: "Reverse String", leetcodeNumber: "344", difficulty: "Easy", goal: "Practice pointer movement. Visualize pointer positions.", weekTheme: weekTheme),
                DSAProblemData(name: "Remove Element", leetcodeNumber: "27", difficulty: "Easy", goal: "Practice pointer movement. Visualize pointer positions.", weekTheme: weekTheme),
                DSAProblemData(name: "Remove Duplicates from Sorted Array", leetcodeNumber: "26", difficulty: "Easy", goal: "Practice pointer movement. Visualize pointer positions.", weekTheme: weekTheme)
            ]
        case 3:
            return [
                DSAProblemData(name: "3Sum", leetcodeNumber: "15", difficulty: "Medium", goal: "Master the expand-around-center and sliding window concepts.", weekTheme: weekTheme),
                DSAProblemData(name: "Container With Most Water", leetcodeNumber: "11", difficulty: "Medium", goal: "Master the expand-around-center and sliding window concepts.", weekTheme: weekTheme),
                DSAProblemData(name: "Valid Palindrome", leetcodeNumber: "125", difficulty: "Easy", goal: "Master the expand-around-center and sliding window concepts.", weekTheme: weekTheme),
                DSAProblemData(name: "Squares of a Sorted Array", leetcodeNumber: "977", difficulty: "Easy", goal: "Master the expand-around-center and sliding window concepts.", weekTheme: weekTheme),
                DSAProblemData(name: "Trapping Rain Water", leetcodeNumber: "42", difficulty: "Hard", goal: "Master the expand-around-center and sliding window concepts.", weekTheme: weekTheme)
            ]
        case 4:
            return [
                DSAProblemData(name: "Range Sum Query - Immutable", leetcodeNumber: "303", difficulty: "Easy", goal: "Understand cumulative sum optimization for range queries.", weekTheme: weekTheme),
                DSAProblemData(name: "Range Sum Query 2D - Immutable", leetcodeNumber: "304", difficulty: "Medium", goal: "Understand cumulative sum optimization for range queries.", weekTheme: weekTheme),
                DSAProblemData(name: "Subarray Sum Equals K", leetcodeNumber: "560", difficulty: "Medium", goal: "Understand cumulative sum optimization for range queries.", weekTheme: weekTheme),
                DSAProblemData(name: "Find Pivot Index", leetcodeNumber: "724", difficulty: "Easy", goal: "Understand cumulative sum optimization for range queries.", weekTheme: weekTheme),
                DSAProblemData(name: "Find the Highest Altitude", leetcodeNumber: "1732", difficulty: "Easy", goal: "Understand cumulative sum optimization for range queries.", weekTheme: weekTheme)
            ]
        case 5:
            return [
                DSAProblemData(name: "Two Sum", leetcodeNumber: "1", difficulty: "Easy", goal: "Master array traversal patterns and space-time trade-offs.", weekTheme: weekTheme),
                DSAProblemData(name: "Product of Array Except Self", leetcodeNumber: "238", difficulty: "Medium", goal: "Master array traversal patterns and space-time trade-offs.", weekTheme: weekTheme),
                DSAProblemData(name: "Maximum Subarray", leetcodeNumber: "53", difficulty: "Easy", goal: "Master array traversal patterns and space-time trade-offs.", weekTheme: weekTheme),
                DSAProblemData(name: "Best Time to Buy and Sell Stock", leetcodeNumber: "121", difficulty: "Easy", goal: "Master array traversal patterns and space-time trade-offs.", weekTheme: weekTheme),
                DSAProblemData(name: "Contains Duplicate", leetcodeNumber: "217", difficulty: "Easy", goal: "Master array traversal patterns and space-time trade-offs.", weekTheme: weekTheme)
            ]
        case 6:
            return [
                DSAProblemData(name: "Majority Element", leetcodeNumber: "169", difficulty: "Easy", goal: "Speed solving - complete all 5 problems in 90 minutes.", weekTheme: weekTheme),
                DSAProblemData(name: "Best Time to Buy and Sell Stock II", leetcodeNumber: "122", difficulty: "Easy", goal: "Speed solving - complete all 5 problems in 90 minutes.", weekTheme: weekTheme),
                DSAProblemData(name: "Single Number", leetcodeNumber: "136", difficulty: "Easy", goal: "Speed solving - complete all 5 problems in 90 minutes.", weekTheme: weekTheme),
                DSAProblemData(name: "Missing Number", leetcodeNumber: "268", difficulty: "Easy", goal: "Speed solving - complete all 5 problems in 90 minutes.", weekTheme: weekTheme),
                DSAProblemData(name: "Find All Numbers Disappeared in an Array", leetcodeNumber: "448", difficulty: "Easy", goal: "Speed solving - complete all 5 problems in 90 minutes.", weekTheme: weekTheme)
            ]
        case 7:
            return [
                DSAProblemData(name: "Max Consecutive Ones", leetcodeNumber: "485", difficulty: "Easy", goal: "Pattern recognition across different problem types.", weekTheme: weekTheme),
                DSAProblemData(name: "Plus One", leetcodeNumber: "66", difficulty: "Easy", goal: "Pattern recognition across different problem types.", weekTheme: weekTheme),
                DSAProblemData(name: "Search Insert Position", leetcodeNumber: "35", difficulty: "Easy", goal: "Pattern recognition across different problem types.", weekTheme: weekTheme),
                DSAProblemData(name: "Length of Last Word", leetcodeNumber: "58", difficulty: "Easy", goal: "Pattern recognition across different problem types.", weekTheme: weekTheme),
                DSAProblemData(name: "Roman to Integer", leetcodeNumber: "13", difficulty: "Easy", goal: "Pattern recognition across different problem types.", weekTheme: weekTheme)
            ]
        case 8:
            return [
                DSAProblemData(name: "Valid Anagram", leetcodeNumber: "242", difficulty: "Easy", goal: "Master hash map operations and frequency counting.", weekTheme: weekTheme),
                DSAProblemData(name: "Intersection of Two Arrays", leetcodeNumber: "349", difficulty: "Easy", goal: "Master hash map operations and frequency counting.", weekTheme: weekTheme),
                DSAProblemData(name: "Happy Number", leetcodeNumber: "202", difficulty: "Easy", goal: "Master hash map operations and frequency counting.", weekTheme: weekTheme),
                DSAProblemData(name: "Isomorphic Strings", leetcodeNumber: "205", difficulty: "Easy", goal: "Master hash map operations and frequency counting.", weekTheme: weekTheme),
                DSAProblemData(name: "Word Pattern", leetcodeNumber: "290", difficulty: "Easy", goal: "Master hash map operations and frequency counting.", weekTheme: weekTheme)
            ]
        case 9:
            return [
                DSAProblemData(name: "Maximum Average Subarray I", leetcodeNumber: "643", difficulty: "Easy", goal: "Master fixed-size sliding window technique.", weekTheme: weekTheme),
                DSAProblemData(name: "Maximum Number of Vowels in a Substring", leetcodeNumber: "1456", difficulty: "Medium", goal: "Master fixed-size sliding window technique.", weekTheme: weekTheme),
                DSAProblemData(name: "Number of Sub-arrays of Size K", leetcodeNumber: "1343", difficulty: "Medium", goal: "Master fixed-size sliding window technique.", weekTheme: weekTheme),
                DSAProblemData(name: "Defuse the Bomb", leetcodeNumber: "1652", difficulty: "Easy", goal: "Master fixed-size sliding window technique.", weekTheme: weekTheme),
                DSAProblemData(name: "Find the K-Beauty of a Number", leetcodeNumber: "2269", difficulty: "Easy", goal: "Master fixed-size sliding window technique.", weekTheme: weekTheme)
            ]
        case 10:
            return [
                DSAProblemData(name: "Longest Substring Without Repeating Characters", leetcodeNumber: "3", difficulty: "Medium", goal: "Master expand-contract sliding window pattern.", weekTheme: weekTheme),
                DSAProblemData(name: "Minimum Window Substring", leetcodeNumber: "76", difficulty: "Hard", goal: "Master expand-contract sliding window pattern.", weekTheme: weekTheme),
                DSAProblemData(name: "Minimum Size Subarray Sum", leetcodeNumber: "209", difficulty: "Medium", goal: "Master expand-contract sliding window pattern.", weekTheme: weekTheme),
                DSAProblemData(name: "Longest Repeating Character Replacement", leetcodeNumber: "424", difficulty: "Medium", goal: "Master expand-contract sliding window pattern.", weekTheme: weekTheme),
                DSAProblemData(name: "Max Consecutive Ones III", leetcodeNumber: "1004", difficulty: "Medium", goal: "Master expand-contract sliding window pattern.", weekTheme: weekTheme)
            ]
        default:
            // For days not yet implemented, return placeholder problems
            return generatePlaceholderProblems(for: day, weekTheme: weekTheme)
        }
    }
    
    static func getSystemDesignTopics(for day: Int) -> [SystemDesignTopicData] {
        let weekTheme = getWeekTheme(for: day)
        
        switch day {
        case 1:
            return [
                SystemDesignTopicData(name: "DNS & Domain Resolution", description: "Watch: 'DNS Explained - How Domain Name System Works' - PowerCert Animated Videos", taskType: .video("DNS Explained - How Domain Name System Works - PowerCert Animated Videos"), videoReference: "DNS Explained - How Domain Name System Works - PowerCert Animated Videos", weekTheme: weekTheme),
                SystemDesignTopicData(name: "Draw DNS Resolution Flow", description: "Client → Resolver → Root → TLD → Authoritative", taskType: .diagram("Draw DNS Resolution Flow → Client → Resolver → Root → TLD → Authoritative"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "DNS Explanation Exercise", description: "Write a 100-word explanation of DNS as if explaining to a child", taskType: .bonus("Write a 100-word explanation of DNS as if you're explaining it to a child"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 2:
            return [
                SystemDesignTopicData(name: "Load Balancing", description: "Watch: 'Load Balancers Explained' - Gaurav Sen", taskType: .video("Load Balancers Explained - Gaurav Sen"), videoReference: "Load Balancers Explained - Gaurav Sen", weekTheme: weekTheme),
                SystemDesignTopicData(name: "Load Balancer Diagram", description: "Diagram Client → Load Balancer → App Servers (Round Robin, Least Connections)", taskType: .diagram("Diagram Client → Load Balancer → App Servers (Round Robin, Least Connections)"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Layer 4 vs Layer 7", description: "Compare Layer 4 vs Layer 7 load balancing in 3 sentences", taskType: .bonus("Compare Layer 4 vs Layer 7 load balancing in 3 sentences"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 3:
            return [
                SystemDesignTopicData(name: "CAP Theorem", description: "Watch: 'CAP Theorem Simplified' - Gaurav Sen", taskType: .video("CAP Theorem Simplified - Gaurav Sen"), videoReference: "CAP Theorem Simplified - Gaurav Sen", weekTheme: weekTheme),
                SystemDesignTopicData(name: "CAP Theorem Scenarios", description: "Draw 3 scenarios showing Consistency, Availability, Partition Tolerance trade-offs", taskType: .diagram("Draw 3 scenarios showing Consistency, Availability, Partition Tolerance trade-offs"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "CAP Examples", description: "Give real-world examples of CP, AP, and CA systems", taskType: .bonus("Give real-world examples of CP, AP, and CA systems"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 4:
            return [
                SystemDesignTopicData(name: "Caching Strategies", description: "Watch: 'Caching Explained' - ByteByteGo", taskType: .video("Caching Explained - ByteByteGo"), videoReference: "Caching Explained - ByteByteGo", weekTheme: weekTheme),
                SystemDesignTopicData(name: "Cache Hierarchy", description: "Draw cache hierarchy (Browser → CDN → Server → Database)", taskType: .diagram("Draw cache hierarchy (Browser → CDN → Server → Database)"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Cache Patterns", description: "Explain cache-aside, write-through, write-behind patterns", taskType: .bonus("Explain cache-aside, write-through, write-behind patterns"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 5:
            return [
                SystemDesignTopicData(name: "RDBMS vs NoSQL", description: "Watch: 'SQL vs NoSQL Database Explained' - Fireship", taskType: .video("SQL vs NoSQL Database Explained - Fireship"), videoReference: "SQL vs NoSQL Database Explained - Fireship", weekTheme: weekTheme),
                SystemDesignTopicData(name: "Database Comparison", description: "Create comparison table with use cases, ACID properties, scaling", taskType: .diagram("Create comparison table with use cases, ACID properties, scaling"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Schema Design", description: "Design simple schema for both SQL and NoSQL for a blog system", taskType: .bonus("Design simple schema for both SQL and NoSQL for a blog system"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 6:
            return [
                SystemDesignTopicData(name: "HTTP/HTTPS & REST APIs", description: "Watch: 'HTTP vs HTTPS Explained' - PowerCert Animated Videos", taskType: .video("HTTP vs HTTPS Explained - PowerCert Animated Videos"), videoReference: "HTTP vs HTTPS Explained - PowerCert Animated Videos", weekTheme: weekTheme),
                SystemDesignTopicData(name: "REST API Design", description: "Design RESTful API endpoints for a simple e-commerce system", taskType: .diagram("Design RESTful API endpoints for a simple e-commerce system"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "HTTP Status Codes", description: "Explain status codes 200, 201, 400, 401, 404, 500", taskType: .bonus("Explain status codes 200, 201, 400, 401, 404, 500"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 7:
            return [
                SystemDesignTopicData(name: "Week 1 Consolidation", description: "Draw complete architecture combining all Week 1 concepts", taskType: .diagram("Draw complete architecture combining all Week 1 concepts"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Web Application Design", description: "Design basic web application with DNS, load balancing, caching, database", taskType: .exercise("Scenario: Design basic web application with DNS, load balancing, caching, database"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Architecture Presentation", description: "Create 5-minute presentation explaining your design", taskType: .bonus("Create 5-minute presentation explaining your design"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 8:
            return [
                SystemDesignTopicData(name: "Message Queues", description: "Watch: 'Message Queues Explained' - Hussein Nasser", taskType: .video("Message Queues Explained - Hussein Nasser"), videoReference: "Message Queues Explained - Hussein Nasser", weekTheme: weekTheme),
                SystemDesignTopicData(name: "Queue Architecture", description: "Draw producer → Queue → Consumer architecture", taskType: .diagram("Draw producer → Queue → Consumer architecture"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Queue Comparison", description: "Compare RabbitMQ vs Apache Kafka use cases", taskType: .bonus("Compare RabbitMQ vs Apache Kafka use cases"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 9:
            return [
                SystemDesignTopicData(name: "File Upload Architecture", description: "Watch: 'File Upload System Design' - Concept && Coding", taskType: .video("File Upload System Design - Concept && Coding"), videoReference: "File Upload System Design - Concept && Coding", weekTheme: weekTheme),
                SystemDesignTopicData(name: "File Upload Flow", description: "Design file upload flow with validation, storage, and CDN", taskType: .diagram("Design file upload flow with validation, storage, and CDN"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Large File Handling", description: "Handle large file uploads with chunking and resume capability", taskType: .bonus("Handle large file uploads with chunking and resume capability"), videoReference: nil, weekTheme: weekTheme)
            ]
        case 10:
            return [
                SystemDesignTopicData(name: "Pub/Sub Systems", description: "Watch: 'Publish Subscribe Pattern' - Defog Tech", taskType: .video("Publish Subscribe Pattern - Defog Tech"), videoReference: "Publish Subscribe Pattern - Defog Tech", weekTheme: weekTheme),
                SystemDesignTopicData(name: "Notification System", description: "Design notification system using pub/sub pattern", taskType: .diagram("Design notification system using pub/sub pattern"), videoReference: nil, weekTheme: weekTheme),
                SystemDesignTopicData(name: "Push vs Pull", description: "Compare push vs pull models for subscribers", taskType: .bonus("Compare push vs pull models for subscribers"), videoReference: nil, weekTheme: weekTheme)
            ]
        default:
            // For days not yet implemented, return placeholder topics
            return generatePlaceholderSystemTopics(for: day, weekTheme: weekTheme)
        }
    }
    
    // MARK: - Placeholder Generation Methods
    
    private static func generatePlaceholderProblems(for day: Int, weekTheme: String) -> [DSAProblemData] {
        // Generate placeholder problems for days not yet implemented
        let problemCount = (day % 3) + 3 // 3-5 problems per day
        var problems: [DSAProblemData] = []
        
        for i in 1...problemCount {
            problems.append(
                DSAProblemData(
                    name: "Day \(day) Problem \(i)",
                    leetcodeNumber: "\(day * 100 + i)",
                    difficulty: ["Easy", "Medium", "Hard"][i % 3],
                    goal: "Complete curriculum implementation for Day \(day) - \(weekTheme)",
                    weekTheme: weekTheme
                )
            )
        }
        
        return problems
    }
    
    private static func generatePlaceholderSystemTopics(for day: Int, weekTheme: String) -> [SystemDesignTopicData] {
        // Generate placeholder system design topics for days not yet implemented
        let topicCount = (day % 2) + 2 // 2-3 topics per day
        var topics: [SystemDesignTopicData] = []
        
        for i in 1...topicCount {
            let taskTypes: [TaskType] = [
                .video("Day \(day) Video \(i)"),
                .diagram("Day \(day) Diagram \(i)"),
                .exercise("Day \(day) Exercise \(i)"),
                .bonus("Day \(day) Bonus \(i)")
            ]
            
            topics.append(
                SystemDesignTopicData(
                    name: "Day \(day) System Topic \(i)",
                    description: "System design topic for Day \(day) - \(weekTheme)",
                    taskType: taskTypes[i % taskTypes.count],
                    videoReference: i == 1 ? "Day \(day) Video Reference" : nil,
                    weekTheme: weekTheme
                )
            )
        }
        
        return topics
    }
}