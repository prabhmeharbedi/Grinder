import CoreData
import Foundation

/// iOS-compatible Core Data validation utility
class CoreDataValidator {
    
    /// Validates that Core Data stack is properly initialized
    static func validateCoreDataStack() -> Bool {
        let context = PersistenceController.shared.container.viewContext
        
        do {
            // Test basic Core Data functionality
            let dayRequest: NSFetchRequest<Day> = Day.fetchRequest()
            dayRequest.fetchLimit = 1
            _ = try context.fetch(dayRequest)
            
            let problemRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
            problemRequest.fetchLimit = 1
            _ = try context.fetch(problemRequest)
            
            let topicRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
            topicRequest.fetchLimit = 1
            _ = try context.fetch(topicRequest)
            
            let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            settingsRequest.fetchLimit = 1
            _ = try context.fetch(settingsRequest)
            
            print("✅ Core Data stack validation successful")
            return true
            
        } catch {
            print("❌ Core Data stack validation failed: \(error)")
            return false
        }
    }
    
    /// Validates that all entities can be created and saved
    static func validateEntityCreation() -> Bool {
        let context = PersistenceController.shared.container.viewContext
        
        do {
            // Create test Day entity
            let testDay = Day(context: context)
            testDay.dayNumber = 999 // Use a test number that won't conflict
            testDay.date = Date()
            testDay.dsaProgress = 0.5
            testDay.systemDesignProgress = 0.3
            testDay.isCompleted = false
            testDay.createdAt = Date()
            testDay.updatedAt = Date()
            
            // Create test DSA Problem
            let testProblem = DSAProblem(context: context)
            testProblem.problemName = "Test Problem"
            testProblem.difficulty = "Easy"
            testProblem.isCompleted = false
            testProblem.timeSpent = 0
            testProblem.createdAt = Date()
            testProblem.updatedAt = Date()
            testProblem.day = testDay
            
            // Create test System Design Topic
            let testTopic = SystemDesignTopic(context: context)
            testTopic.topicName = "Test Topic"
            testTopic.isCompleted = false
            testTopic.videoWatched = false
            testTopic.taskCompleted = false
            testTopic.createdAt = Date()
            testTopic.updatedAt = Date()
            testTopic.day = testDay
            
            // Test save
            try context.save()
            
            // Clean up test data
            context.delete(testProblem)
            context.delete(testTopic)
            context.delete(testDay)
            try context.save()
            
            print("✅ Entity creation validation successful")
            return true
            
        } catch {
            print("❌ Entity creation validation failed: \(error)")
            // Rollback any changes
            context.rollback()
            return false
        }
    }
    
    /// Validates that validation errors work correctly
    static func validateValidationErrors() -> Bool {
        let context = PersistenceController.shared.container.viewContext
        
        do {
            // Test invalid day number
            let invalidDay = Day(context: context)
            invalidDay.dayNumber = 101 // Invalid - should be 1-100
            invalidDay.dsaProgress = 0.0
            invalidDay.systemDesignProgress = 0.0
            
            // This should throw a validation error
            try invalidDay.validateForInsert()
            
            print("❌ Validation should have failed for invalid day number")
            return false
            
        } catch ValidationError.invalidDayNumber {
            print("✅ Validation error handling works correctly")
            context.rollback()
            return true
        } catch {
            print("❌ Unexpected validation error: \(error)")
            context.rollback()
            return false
        }
    }
    
    /// Runs all validation tests
    static func runAllValidations() -> Bool {
        print("🧪 Running Core Data validation tests...")
        
        let stackValid = validateCoreDataStack()
        let creationValid = validateEntityCreation()
        let validationValid = validateValidationErrors()
        
        let allValid = stackValid && creationValid && validationValid
        
        if allValid {
            print("🎉 All Core Data validations passed!")
        } else {
            print("❌ Some Core Data validations failed")
        }
        
        return allValid
    }
}