import CoreData
import UIKit
import CoreLocation
import RxSwift
import UserNotifications

class DefaultSettingsService : SettingsService
{
    //MARK: Public Properties
    
    var installDate : Date?
    {
        return get(forKey: installDateKey)
    }
    
    var isFirstTimeAppRuns : Bool
    {
        return !getBool(forKey: isFirstTimeAppRunsKey)
    }
    
    var isPostCoreMotionUser : Bool
    {
        return getBool(forKey: isPostCoreMotionUserKey)
    }
    
    var lastLocation : Location?
    {
        var location : Location? = nil
        
        let possibleTime = get(forKey: lastLocationDateKey) as Date?
        
        if let time = possibleTime
        {
            let latitude = getDouble(forKey: lastLocationLatKey)
            let longitude = getDouble(forKey: lastLocationLngKey)
            let horizontalAccuracy = get(forKey: lastLocationHorizontalAccuracyKey) as Double? ?? 0.0
            
            location = Location(timestamp: time,
                                latitude: latitude, longitude: longitude,
                                accuracy: horizontalAccuracy)
        }
        
        return location
    }
    
    var lastTimelineGenerationDate: Date?
    {
        return get(forKey: lastTimelineGenerationDateKey)
    }
    
    var hasLocationPermission : Bool
    {
        guard CLLocationManager.locationServicesEnabled() else { return false }
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    var hasCoreMotionPermission : Bool
    {
        return getBool(forKey: hasCoreMotionPermissionKey)
    }
    
    var hasNotificationPermission : Observable<Bool>
    {
        return Observable<Bool>.create { observer in

            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.getNotificationSettings { settings in
                let authorized = settings.authorizationStatus == UNAuthorizationStatus.authorized
                observer.onNext(authorized)
                observer.onCompleted()
            }

            return Disposables.create { }
        }.observeOn(CurrentThreadScheduler.instance)
    }
    
    var shouldAskForNotificationPermission : Bool
    {
        return getBool(forKey: shouldAskForNotificationPermissionKey)
    }
    
    var userRejectedNotificationPermission: Bool
    {
        return getBool(forKey: userRejectedNotificationPermissionKey)
    }
    
    var didAlreadyShowRequestForNotificationsInNewGoal : Bool
    {
        return getBool(forKey: didAlreadyShowRequestForNotificationsInNewGoalKey)
    }
    
    var userEverGaveLocationPermission: Bool
    {
        return getBool(forKey: userGaveLocationPermissionKey)
    }
    
    var userEverGaveMotionPermission: Bool
    {
        return getBool(forKey: userGaveMotionPermissionKey)
    }
    
    var didShowWelcomeMessage : Bool
    {
        return getBool(forKey: welcomeMessageShownKey)
    }
    
    var lastShownWeeklyRating : Date?
    {
        return get(forKey: lastShownWeeklyRatingKey)
    }
    
    var motionPermissionGranted: Observable<Bool>
    {
        return UserDefaults.standard.rx.observe(Bool.self, hasCoreMotionPermissionKey)
            .filterNil()
    }
    
    var lastUsedGoalAchivedMessageAndDate: [Date: String]?
    {
        if let archive = UserDefaults.standard.value(forKey: lastUsedGoalAchivedMessageAndDateKey) as? NSData
        {
            return NSKeyedUnarchiver.unarchiveObject(with: archive as Data) as? [Date: String]
        }
        
        return nil
    }
    
    var lastShownAddGoalAlert: Date? {
        return get(forKey: lastShownGoalAlertKey)
    }
    
    var lastShownGoalSuggestion: Date?
    {
        return get(forKey: lastShownGoalSuggestionKey)
    }

    var versionNumber: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var lastGoalLoggingDate: Date?
    {
        return get(forKey: lastGoalLoggingDateKey)
    }

    //MARK: Private Properties
    
    private let timeService : TimeService
    
    private let installDateKey = "installDate"
    private let lastLocationLatKey = "lastLocationLat"
    private let lastLocationLngKey = "lastLocationLng"
    private let lastLocationDateKey = "lastLocationDate"
    private let lastLocationHorizontalAccuracyKey = "lastLocationHorizongalAccuracy"
    private let userGaveLocationPermissionKey = "canIgnoreLocationPermission"
    private let userGaveMotionPermissionKey = "userGaveMotionPermissionKey"
    private let userRejectedNotificationPermissionKey = "userRejectedNotificationPermission"
    private let welcomeMessageShownKey = "welcomeMessageShown"
    private let votingHistoryKey = "votingHistory"
    private let lastShownWeeklyRatingKey = "lastShownWeeklyRating"
    private let isFirstTimeAppRunsKey = "isFirstTimeAppRuns"
    private let isPostCoreMotionUserKey = "isPostCoreMotionUser"
    private let hasCoreMotionPermissionKey = "hasCoreMotionPermission"
    private let lastTimelineGenerationDateKey = "lastTimelineGenerationDate"
    private let shouldAskForNotificationPermissionKey = "shouldAskForNotificationPermission"
    private let lastUsedGoalAchivedMessageAndDateKey = "lastUsedGoalAchivedMessageAndDate"
    private let lastShownGoalAlertKey = "lastShownGoalAlert"
    private let lastShownGoalSuggestionKey = "lastShownGoalSuggestion"
    private let lastGoalLoggingDateKey = "lastGoalLoggingDate"
    private let didAlreadyShowRequestForNotificationsInNewGoalKey = "didAlreadyShowRequestForNotificationsInNewGoal"
    
    //MARK: Initialiazers
    init (timeService : TimeService)
    {
        self.timeService = timeService
    }

    //MARK: Public Methods
    func setIsFirstTimeAppRuns()
    {
        set(true, forKey: isFirstTimeAppRunsKey)
    }
    
    func setIsPostCoreMotionUser()
    {
        set(true, forKey: isPostCoreMotionUserKey)
    }
    
    func setInstallDate(_ date: Date)
    {
        guard installDate == nil else { return }
        
        set(date, forKey: installDateKey)
    }
    
    func setLastLocation(_ location: Location)
    {
        set(location.timestamp, forKey: lastLocationDateKey)
        set(location.latitude, forKey: lastLocationLatKey)
        set(location.longitude, forKey: lastLocationLngKey)
        set(location.horizontalAccuracy, forKey: lastLocationHorizontalAccuracyKey)
    }
    
    func setLastTimelineGenerationDate(_ date: Date)
    {
        set(date, forKey: lastTimelineGenerationDateKey)
    }
    
    func setUserGaveLocationPermission()
    {
        set(true, forKey: userGaveLocationPermissionKey)
    }
    
    func setCoreMotionPermission(userGavePermission: Bool)
    {
        set(true, forKey: userGaveMotionPermissionKey)
        set(userGavePermission, forKey: hasCoreMotionPermissionKey)
    }
    
    func setUserRejectedNotificationPermission()
    {
        set(true, forKey: userRejectedNotificationPermissionKey)
    }
    
    func setDidAlreadyShowRequestForNotificationsInNewGoal()
    {
        set(true, forKey: didAlreadyShowRequestForNotificationsInNewGoalKey)
    }
    
    func setShouldAskForNotificationPermission()
    {
        set(true, forKey: shouldAskForNotificationPermissionKey)
    }
    
    func setWelcomeMessageShown()
    {
        set(true, forKey: welcomeMessageShownKey)
    }
    
    func setVote(forDate date: Date)
    {
        var history = lastSevenDaysOfVotingHistory()
        history.append(date.ignoreTimeComponents())
        UserDefaults.standard.setValue(history, forKey: votingHistoryKey)
    }
    
    func lastSevenDaysOfVotingHistory() -> [Date]
    {
        guard let history = UserDefaults.standard.object(forKey: votingHistoryKey) as? [Date]
        else
        {
            let history = [Date]()
            UserDefaults.standard.setValue(history, forKey: votingHistoryKey)
            return history
        }
        
        let cleanedUpHistory = history.filter { timeService.now.timeIntervalSince($0) < Constants.sevenDaysInSeconds }
        
        UserDefaults.standard.setValue(cleanedUpHistory, forKey: votingHistoryKey)
        
        return cleanedUpHistory
    }
    
    func setLastShownWeeklyRating(_ date: Date)
    {
        set(date, forKey: lastShownWeeklyRatingKey)
    }
    
    func setLastUsedGoalAchivedMessageAndDate(_ data: [Date: String])
    {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: data), forKey: lastUsedGoalAchivedMessageAndDateKey)
    }
    
    func setLastShownAddGoalAlert(_ date: Date)
    {
        set(date, forKey: lastShownGoalAlertKey)
    }
    
    func setLastShownGoalSuggestion(_ date: Date)
    {
        set(date, forKey: lastShownGoalSuggestionKey)
    }
    
    func setLastGoalLoggingDate(_ date: Date)
    {
        set(date, forKey: lastGoalLoggingDateKey)
    }
    
    // MARK: Private Methods
    private func get<T>(forKey key: String) -> T?
    {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    private func getDouble(forKey key: String) -> Double
    {
        return UserDefaults.standard.double(forKey: key)
    }
    private func getBool(forKey key: String) -> Bool
    {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func set(_ value: Date?, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func set(_ value: Double, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func set(_ value: Bool, forKey key: String)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
}
