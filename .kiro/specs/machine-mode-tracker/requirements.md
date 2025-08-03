# Requirements Document

## Introduction

The Machine Mode Tracker is a comprehensive iOS application designed to track and maintain accountability for a 100-day intensive software engineering interview preparation program. The app focuses on persistent data storage across development build cycles, ensuring that user progress is never lost even when the app needs to be rebuilt every 7 days due to development certificate limitations.

The core mission is to provide a simple, focused progress tracking system for DSA problems and System Design topics with daily accountability, smart notifications, and comprehensive data persistence across app rebuilds.

## Requirements

### Requirement 1: Daily Progress Tracking

**User Story:** As a software engineering candidate, I want to track my daily completion of DSA problems and System Design topics, so that I can maintain consistent progress through my 100-day preparation program.

#### Acceptance Criteria

1. WHEN the user opens the app THEN the system SHALL display the current day number (Day X/100)
2. WHEN the user views today's tasks THEN the system SHALL show DSA problems for the current day with checkboxes
3. WHEN the user views today's tasks THEN the system SHALL show System Design topics for the current day with checkboxes
4. WHEN the user marks an item as complete THEN the system SHALL update progress bars in real-time
5. WHEN the user completes items THEN the system SHALL calculate separate progress percentages for DSA and System Design
6. WHEN the user wants to track time THEN the system SHALL allow optional time tracking per problem
7. WHEN the user wants to add notes THEN the system SHALL allow optional notes per problem/topic
8. WHEN the user wants to do extra work THEN the system SHALL allow adding bonus problems beyond daily requirements

### Requirement 2: Data Persistence Across Rebuilds

**User Story:** As a developer using a free Apple account, I want my progress data to persist when I rebuild the app every 7 days, so that I never lose my tracking progress.

#### Acceptance Criteria

1. WHEN the app is rebuilt THEN the system SHALL preserve all user progress data
2. WHEN the app launches after rebuild THEN the system SHALL detect the rebuild and verify data integrity
3. WHEN data is modified THEN the system SHALL store it in the iOS Documents directory for persistence
4. WHEN the app approaches expiration THEN the system SHALL create automatic backups
5. WHEN the user requests it THEN the system SHALL create manual backups
6. WHEN the app is rebuilt THEN the system SHALL maintain user settings and preferences
7. WHEN data corruption is detected THEN the system SHALL attempt recovery from backups

### Requirement 3: Smart Notification System

**User Story:** As a busy candidate, I want to receive motivational notifications and reminders, so that I stay consistent with my daily practice routine.

#### Acceptance Criteria

1. WHEN the morning time arrives THEN the system SHALL send a motivational notification
2. WHEN the evening time arrives THEN the system SHALL send a progress check notification
3. WHEN the user configures settings THEN the system SHALL allow custom notification times
4. WHEN the user achieves milestones THEN the system SHALL send streak alert notifications
5. WHEN no progress is logged by evening THEN the system SHALL send a gentle reminder
6. WHEN it's Sunday evening THEN the system SHALL send weekly review prompts
7. WHEN the app is about to expire THEN the system SHALL send rebuild reminders

### Requirement 4: Visual Progress Dashboard

**User Story:** As a motivated learner, I want to see visual representations of my progress, so that I can stay motivated and track my consistency over time.

#### Acceptance Criteria

1. WHEN the user views progress THEN the system SHALL display overall completion percentage out of 100 days
2. WHEN the user views progress THEN the system SHALL show DSA vs System Design completion split
3. WHEN the user views progress THEN the system SHALL display a weekly heat map showing consistency
4. WHEN the user views progress THEN the system SHALL show problem difficulty distribution
5. WHEN the user views progress THEN the system SHALL display current streak counter with badges
6. WHEN the user views progress THEN the system SHALL show historical progress charts
7. WHEN the user achieves milestones THEN the system SHALL display achievement indicators

### Requirement 5: Comprehensive Export System

**User Story:** As a candidate who wants to share progress, I want to export my data in multiple formats, so that I can update my original markdown files and share achievements.

#### Acceptance Criteria

1. WHEN the user requests export THEN the system SHALL generate markdown format progress reports
2. WHEN the user requests export THEN the system SHALL generate JSON format data backups
3. WHEN the user exports data THEN the system SHALL include completion status for all problems
4. WHEN the user exports data THEN the system SHALL include time spent and notes for each item
5. WHEN the user exports data THEN the system SHALL include overall statistics and streaks
6. WHEN the user exports data THEN the system SHALL allow sharing via standard iOS sharing
7. WHEN the user exports data THEN the system SHALL preserve data formatting for easy reading

### Requirement 6: Curriculum Data Management

**User Story:** As a user starting the program, I want the app to be pre-loaded with the complete 100-day curriculum, so that I can immediately begin tracking without manual setup.

#### Acceptance Criteria

1. WHEN the app launches for the first time THEN the system SHALL initialize all 100 days of curriculum data
2. WHEN curriculum is initialized THEN the system SHALL include all DSA problems with LeetCode numbers and difficulty levels
3. WHEN curriculum is initialized THEN the system SHALL include all System Design topics with descriptions
4. WHEN the user views any day THEN the system SHALL display the correct problems and topics for that day
5. WHEN the user adds bonus problems THEN the system SHALL distinguish them from curriculum problems
6. WHEN data is corrupted THEN the system SHALL be able to reinitialize curriculum data
7. WHEN the app is updated THEN the system SHALL preserve user progress while updating curriculum if needed

### Requirement 7: App Lifecycle Management

**User Story:** As a developer using development builds, I want the app to handle the 7-day expiration cycle gracefully, so that I can maintain my tracking routine without data loss.

#### Acceptance Criteria

1. WHEN the app is installed THEN the system SHALL track the installation date
2. WHEN the app calculates expiration THEN the system SHALL show days remaining until expiration
3. WHEN expiration is approaching THEN the system SHALL display warning messages
4. WHEN the app is rebuilt THEN the system SHALL detect the rebuild and create automatic backups
5. WHEN the app is rebuilt THEN the system SHALL verify data integrity and report status
6. WHEN expiration warnings appear THEN the system SHALL provide backup creation options
7. WHEN the app expires THEN the system SHALL ensure all data remains in Documents directory for next build

### Requirement 8: User Experience and Performance

**User Story:** As a daily user, I want the app to be fast, intuitive, and reliable, so that tracking my progress is effortless and doesn't interfere with my study time.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL load in under 2 seconds
2. WHEN the user interacts with checkboxes THEN the system SHALL respond immediately with visual feedback
3. WHEN the user navigates between tabs THEN the system SHALL maintain smooth 60 FPS performance
4. WHEN the user adds notes THEN the system SHALL auto-save changes without user intervention
5. WHEN the user uses the app THEN the system SHALL support both light and dark mode
6. WHEN the user has accessibility needs THEN the system SHALL support VoiceOver and accessibility features
7. WHEN the app encounters errors THEN the system SHALL handle them gracefully without data loss