import Foundation
import UserNotifications
import CoreData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let persistenceController = PersistenceController.shared
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Permission Management
    
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permissions granted")
                    self?.scheduleAllNotifications()
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("⚠️ Notification permissions denied")
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    print("✅ Notifications authorized")
                    self.scheduleAllNotifications()
                case .denied:
                    print("❌ Notifications denied")
                case .notDetermined:
                    print("⚠️ Notification permission not determined")
                    self.requestPermission()
                case .provisional:
                    print("📱 Provisional notification access")
                case .ephemeral:
                    print("⏰ Ephemeral notification access")
                @unknown default:
                    print("❓ Unknown notification status")
                }
            }
        }
    }
    
    // MARK: - Notification Categories Setup
    
    private func setupNotificationCategories() {
        let viewProgressAction = UNNotificationAction(
            identifier: "VIEW_PROGRESS",
            title: "View Progress",
            options: [.foreground]
        )
        
        let createBackupAction = UNNotificationAction(
            identifier: "CREATE_BACKUP",
            title: "Create Backup",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )
        
        // Morning motivation category
        let morningCategory = UNNotificationCategory(
            identifier: "MORNING_MOTIVATION",
            actions: [viewProgressAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Evening progress check category
        let eveningCategory = UNNotificationCategory(
            identifier: "EVENING_PROGRESS",
            actions: [viewProgressAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Streak alert category
        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_ALERT",
            actions: [viewProgressAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Milestone achievement category
        let milestoneCategory = UNNotificationCategory(
            identifier: "MILESTONE_ACHIEVEMENT",
            actions: [viewProgressAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Gentle reminder category
        let reminderCategory = UNNotificationCategory(
            identifier: "GENTLE_REMINDER",
            actions: [viewProgressAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Weekly review category
        let weeklyReviewCategory = UNNotificationCategory(
            identifier: "WEEKLY_REVIEW",
            actions: [viewProgressAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Rebuild reminder category
        let rebuildReminderCategory = UNNotificationCategory(
            identifier: "REBUILD_REMINDER",
            actions: [createBackupAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([
            morningCategory,
            eveningCategory,
            streakCategory,
            milestoneCategory,
            reminderCategory,
            weeklyReviewCategory,
            rebuildReminderCategory
        ])
        
        print("✅ Notification categories configured")
    }
    
    // MARK: - Main Scheduling Methods
    
    func scheduleAllNotifications() {
        guard let userSettings = getUserSettings() else {
            print("⚠️ No user settings found, using default notification times")
            scheduleWithDefaultTimes()
            return
        }
        
        if userSettings.isNotificationsEnabled {
            scheduleMorningMotivation(time: userSettings.morningNotificationTime)
            scheduleEveningProgressCheck(time: userSettings.eveningNotificationTime)
            scheduleWeeklyReview()
            checkAndScheduleStreakAlerts()
            checkAndScheduleMilestoneNotifications()
            scheduleGentleReminders()
        }
    }
    
    private func scheduleWithDefaultTimes() {
        let calendar = Calendar.current
        let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        
        scheduleMorningMotivation(time: morningTime)
        scheduleEveningProgressCheck(time: eveningTime)
        scheduleWeeklyReview()
    }
    
    // MARK: - Morning Motivational Notifications
    
    func scheduleMorningMotivation(time: Date?) {
        let calendar = Calendar.current
        let notificationTime = time ?? calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "🚀 Machine Mode Activated!"
        content.body = getRandomMotivationalMessage()
        content.sound = .default
        content.categoryIdentifier = "MORNING_MOTIVATION"
        content.badge = 1
        
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "morning_motivation",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling morning motivation: \(error)")
            } else {
                print("✅ Morning motivation scheduled for \(components.hour ?? 8):\(String(format: "%02d", components.minute ?? 0))")
            }
        }
    }
    
    private func getRandomMotivationalMessage() -> String {
        let messages = [
            "Time to level up your coding skills! 💪",
            "Every problem solved is a step closer to your dream job! 🎯",
            "Consistency beats perfection. Let's code! 👨‍💻",
            "Your future self will thank you for today's effort! 🌟",
            "Great developers are made through daily practice! 🔥",
            "Today's challenges are tomorrow's strengths! 💡",
            "Code with purpose, practice with passion! ❤️",
            "Small daily improvements lead to stunning results! 📈",
            "Your coding journey continues today! 🛤️",
            "Transform problems into opportunities! ⚡"
        ]
        return messages.randomElement() ?? "Ready to code today? Let's go! 🚀"
    }
    
    // MARK: - Evening Progress Check Notifications
    
    func scheduleEveningProgressCheck(time: Date?) {
        let calendar = Calendar.current
        let notificationTime = time ?? calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "📊 Daily Progress Check"
        content.body = "How did your coding practice go today? Check your progress!"
        content.sound = .default
        content.categoryIdentifier = "EVENING_PROGRESS"
        content.badge = 1
        
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "evening_progress",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling evening progress check: \(error)")
            } else {
                print("✅ Evening progress check scheduled for \(components.hour ?? 20):\(String(format: "%02d", components.minute ?? 0))")
            }
        }
    }
    
    // MARK: - Streak Alerts
    
    func checkAndScheduleStreakAlerts() {
        guard let userSettings = getUserSettings() else { return }
        
        let currentStreak = userSettings.currentStreak
        
        // Schedule streak milestone notifications
        if currentStreak > 0 && currentStreak % 7 == 0 {
            scheduleStreakMilestone(streak: currentStreak)
        }
        
        // Schedule streak warning if no progress today
        if !hasProgressToday() {
            scheduleStreakWarning()
        }
    }
    
    private func scheduleStreakMilestone(streak: Int32) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Milestone!"
        content.body = "Amazing! You've maintained a \(streak)-day streak! Keep the momentum going!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_ALERT"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "streak_milestone_\(streak)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling streak milestone: \(error)")
            } else {
                print("✅ Streak milestone notification scheduled for \(streak) days")
            }
        }
    }
    
    private func scheduleStreakWarning() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Streak at Risk!"
        content.body = "Don't break your streak! Complete today's practice to keep your momentum."
        content.sound = .default
        content.categoryIdentifier = "STREAK_ALERT"
        content.badge = 1
        
        // Schedule for 30 minutes from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "streak_warning_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling streak warning: \(error)")
            } else {
                print("✅ Streak warning scheduled")
            }
        }
    }
    
    // MARK: - Milestone Achievement Notifications
    
    func checkAndScheduleMilestoneNotifications() {
        let totalCompletedDays = getTotalCompletedDays()
        
        let milestones = [10, 25, 50, 75, 100]
        
        for milestone in milestones {
            if totalCompletedDays == milestone {
                scheduleMilestoneAchievement(days: milestone)
            }
        }
    }
    
    private func scheduleMilestoneAchievement(days: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Milestone Achieved!"
        
        let message: String
        switch days {
        case 10:
            message = "You've completed 10 days! You're building great habits! 🌱"
        case 25:
            message = "Quarter way there! 25 days completed - you're unstoppable! 💪"
        case 50:
            message = "Halfway milestone! 50 days of consistent practice! 🏆"
        case 75:
            message = "75 days completed! You're in the final stretch! 🚀"
        case 100:
            message = "INCREDIBLE! You've completed the full 100-day challenge! 🎊"
        default:
            message = "You've completed \(days) days of practice! Keep going! 🌟"
        }
        
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "MILESTONE_ACHIEVEMENT"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "milestone_\(days)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling milestone achievement: \(error)")
            } else {
                print("✅ Milestone achievement notification scheduled for \(days) days")
            }
        }
    }
    
    // MARK: - Gentle Reminders
    
    func scheduleGentleReminders() {
        // Schedule reminder for incomplete daily progress (evening)
        let calendar = Calendar.current
        let reminderTime = calendar.date(bySettingHour: 21, minute: 30, second: 0, of: Date()) ?? Date()
        
        let content = UNMutableNotificationContent()
        content.title = "💡 Gentle Reminder"
        content.body = "A few minutes of practice can make a big difference. Every step counts!"
        content.sound = .default
        content.categoryIdentifier = "GENTLE_REMINDER"
        content.badge = 1
        
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "gentle_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling gentle reminder: \(error)")
            } else {
                print("✅ Gentle reminder scheduled for 21:30")
            }
        }
    }
    
    // MARK: - Weekly Review Prompts
    
    func scheduleWeeklyReview() {
        let calendar = Calendar.current
        
        // Schedule for Sunday evening at 7 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "📝 Weekly Review Time"
        content.body = "Take a moment to reflect on this week's progress and plan for the next!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REVIEW"
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling weekly review: \(error)")
            } else {
                print("✅ Weekly review scheduled for Sundays at 19:00")
            }
        }
    }
    
    // MARK: - Rebuild Reminders
    
    func scheduleRebuildReminder(daysUntilExpiration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ App Rebuild Reminder"
        
        let message: String
        switch daysUntilExpiration {
        case 3:
            message = "Your app expires in 3 days. Consider creating a backup and preparing for rebuild."
        case 1:
            message = "Your app expires tomorrow! Create a backup now to preserve your progress."
        case 0:
            message = "Your app expires today! Create a backup immediately and rebuild the app."
        default:
            message = "Your app expires in \(daysUntilExpiration) days. Plan ahead to avoid data loss."
        }
        
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "REBUILD_REMINDER"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "rebuild_reminder_\(daysUntilExpiration)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling rebuild reminder: \(error)")
            } else {
                print("✅ Rebuild reminder scheduled for \(daysUntilExpiration) days")
            }
        }
    }
    
    func scheduleRebuildNotification() {
        let content = UNMutableNotificationContent()
        content.title = "✅ App Rebuild Successful"
        content.body = "Your app has been successfully rebuilt! All your progress data has been preserved."
        content.sound = .default
        content.categoryIdentifier = "REBUILD_REMINDER"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "rebuild_success",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling rebuild success notification: \(error)")
            } else {
                print("✅ Rebuild success notification scheduled")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("✅ All notifications cancelled")
    }
    
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ Notification cancelled: \(identifier)")
    }
    
    // MARK: - Data Helper Methods
    
    private func getUserSettings() -> UserSettings? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(request)
            return settings.first
        } catch {
            print("❌ Error fetching user settings: \(error)")
            return nil
        }
    }
    
    private func hasProgressToday() -> Bool {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", today as NSDate, tomorrow as NSDate)
        
        do {
            let todayDays = try context.fetch(request)
            return todayDays.first?.isCompleted == true || 
                   todayDays.first?.dsaProgress ?? 0 > 0 || 
                   todayDays.first?.systemDesignProgress ?? 0 > 0
        } catch {
            print("❌ Error checking today's progress: \(error)")
            return false
        }
    }
    
    private func getTotalCompletedDays() -> Int {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        
        do {
            return try context.count(for: request)
        } catch {
            print("❌ Error counting completed days: \(error)")
            return 0
        }
    }
    
    // MARK: - Streak Management
    
    func updateStreakAndCheckMilestones() {
        guard let userSettings = getUserSettings() else { return }
        
        let context = persistenceController.container.viewContext
        
        // Check if today has any progress
        if hasProgressToday() {
            // Update current streak
            let newStreak = userSettings.currentStreak + 1
            userSettings.currentStreak = newStreak
            
            // Update longest streak if needed
            if newStreak > userSettings.longestStreak {
                userSettings.longestStreak = newStreak
            }
            
            // Check for streak milestones
            if newStreak > 0 && newStreak % 7 == 0 {
                scheduleStreakMilestone(streak: newStreak)
            }
            
            do {
                try context.save()
                print("✅ Streak updated to \(newStreak) days")
            } catch {
                print("❌ Error updating streak: \(error)")
            }
        }
        
        // Check for overall milestones
        checkAndScheduleMilestoneNotifications()
    }
    
    func resetStreakIfNeeded() {
        guard let userSettings = getUserSettings() else { return }
        
        let context = persistenceController.container.viewContext
        
        // Check if yesterday had no progress (streak broken)
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        if !hasProgressForDate(yesterday) && userSettings.currentStreak > 0 {
            userSettings.currentStreak = 0
            
            do {
                try context.save()
                print("💔 Streak reset due to missed day")
            } catch {
                print("❌ Error resetting streak: \(error)")
            }
        }
    }
    
    private func hasProgressForDate(_ date: Date) -> Bool {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let days = try context.fetch(request)
            return days.first?.isCompleted == true || 
                   days.first?.dsaProgress ?? 0 > 0 || 
                   days.first?.systemDesignProgress ?? 0 > 0
        } catch {
            print("❌ Error checking progress for date: \(error)")
            return false
        }
    }
    
    // MARK: - Debug Methods
    
    func listPendingNotifications() {
        center.getPendingNotificationRequests { requests in
            print("📱 Pending notifications: \(requests.count)")
            for request in requests {
                print("  - \(request.identifier): \(request.content.title)")
            }
        }
    }
    
    func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "This is a test notification from Machine Mode Tracker!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error)")
            } else {
                print("✅ Test notification scheduled")
            }
        }
    }
    
    // MARK: - Settings Integration
    
    func updateNotificationTimes(morningTime: Date, eveningTime: Date) {
        // Cancel existing daily notifications
        center.removePendingNotificationRequests(withIdentifiers: ["morning_motivation", "evening_progress"])
        
        // Schedule new notifications with updated times
        scheduleMorningMotivation(time: morningTime)
        scheduleEveningProgressCheck(time: eveningTime)
        
        print("✅ Notification times updated")
    }
    
    func enableNotifications(_ enabled: Bool) {
        if enabled {
            requestPermission()
        } else {
            cancelAllNotifications()
        }
    }
}