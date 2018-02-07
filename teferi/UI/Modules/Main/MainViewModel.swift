import Foundation
import RxSwift

///ViewModel for the MainViewController.
class MainViewModel : RxViewModel
{
    // MARK: Public Properties
    let dateObservable : Observable<Date>
    let isEditingObservable : Observable<Bool>
    let beganEditingObservable : Observable<(CGPoint, SlotTimelineItem)>
    let categoryProvider : CategoryProvider
    
    var currentDate : Date { return self.timeService.now }
    
    var showPermissionControllerObservable : Observable<PermissionRequestType>
    {
        return Observable.of(
            self.appLifecycleService.movedToForegroundObservable,
            self.didBecomeActive,
            self.motionService.motionAuthorizationGranted.mapTo(()))
            .merge()
            .flatMap { [unowned self] () -> Observable<PermissionRequestType> in
                let locationPermissionRequest = self.shouldShowLocationPermissionRequest().filter({$0}).mapTo(PermissionRequestType.location)
                let motionPermissionRequest = self.shouldShowMotionPermissionRequest().filter({$0}).mapTo(PermissionRequestType.motion)
                let notificationPermissionRequest = self.shouldShowNotificationPermissionRequest().filter({$0}).mapTo(PermissionRequestType.notification)
                
                return Observable.of(locationPermissionRequest, motionPermissionRequest, notificationPermissionRequest).concat().take(1)
            }
    }
    
    var welcomeMessageHiddenObservable : Observable<Bool>
    {
        if self.settingsService.didShowWelcomeMessage {
            return Observable.just(true)
        }
        
        if
            timeService.now.ignoreTimeComponents() == settingsService.installDate?.ignoreTimeComponents(),
            let _ = timeSlotService.getLast()
        {
            return Observable.of(
                self.didBecomeActive.skip(1),
                self.beganEditingObservable.mapTo(()),
                self.timeSlotService.timeSlotCreatedObservable.mapTo(()).skip(1))
                .merge()
                .mapTo(true)
                .startWith(false)
                .do(onNext: { _ in
                    self.settingsService.setWelcomeMessageShown()
                })
        }
        else
        {
            return Observable.just(true)
        }
    }
    
    var moveToForegroundObservable : Observable<Void>
    {
        return appLifecycleService.movedToForegroundObservable
    }
    
    var shouldShowCMAccessForExistingUsers : Bool
    {
        return !settingsService.isPostCoreMotionUser && !settingsService.hasCoreMotionPermission
    }
    
    var shouldShowWeeklyRatingUI : Bool
    {
        guard let installDate = settingsService.installDate else { return false }
        
        if
            let lastShown = settingsService.lastShownWeeklyRating,
            lastShown.ignoreTimeComponents() == timeService.now.ignoreTimeComponents() || lastShown.ignoreTimeComponents() == timeService.now.add(days: -1).ignoreTimeComponents()
        {
            return false
        }
        
        let itIsSevenOrMoreDaysSinceTheAppInstall = timeService.now.timeIntervalSince(installDate) >= Constants.sevenDaysInSeconds
        let itIsSundayAfterWeeklyRatingHour = (timeService.now.dayOfWeek == 0 ? timeService.now.hour >= Constants.hourToShowWeeklyRatingUI : false)
        let itIsMondayBeforeWeeklyRatingHour = (timeService.now.dayOfWeek == 1 ? timeService.now.hour < Constants.hourToShowWeeklyRatingUI : false)
        let itIsInTheRangeBetweenSundayAfterWeeklyRatingHourAndModayBeforeWeeklyRatingHour = itIsSundayAfterWeeklyRatingHour || itIsMondayBeforeWeeklyRatingHour
        
        let shouldShowRatingUI = itIsSevenOrMoreDaysSinceTheAppInstall && itIsInTheRangeBetweenSundayAfterWeeklyRatingHourAndModayBeforeWeeklyRatingHour
        
        return shouldShowRatingUI
    }
    
    var weeklyRatingStartDate : Date
    {
        return timeService.now.add(days: -6)
    }
    
    var weeklyRatingEndDate : Date
    {
        return timeService.now
    }

    var locating:Observable<Bool> {
        return locatingActivity.asObservable()
            .observeOn(MainScheduler.instance)
    }
    
    var generating: Observable<Bool> {
        return generatingTimelineActivity.asObservable()
            .observeOn(MainScheduler.instance)
    }
    
    var showAddGoalAlert: Observable<Bool> {
        return Observable.of(
            self.appLifecycleService.movedToForegroundObservable,
            self.didBecomeActive)
            .merge()
            .filter{ [unowned self] _ in
                guard let lastShown = self.settingsService.lastShownAddGoalAlert else { return true }
                return self.timeService.now.ignoreTimeComponents() > lastShown.ignoreTimeComponents()
            }
            .map { [unowned self] _ in
                guard let lastGoal = self.goalService.getGoals(sinceDaysAgo: 1).first else { return true }
                return self.timeService.now.ignoreTimeComponents() > lastGoal.date.ignoreTimeComponents()
            }            
    }
    
    // MARK: Private Properties
    private let loggingService: LoggingService
    private let timeService : TimeService
    private let metricsService : MetricsService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let smartGuessService : SmartGuessService
    private let settingsService : SettingsService
    private let appLifecycleService : AppLifecycleService
    private let locationService: LocationService
    private let trackEventService: TrackEventService
    private let motionService: MotionService
    private let goalService: GoalService
    
    private let locatingActivity = ActivityIndicator()
    private let generatingTimelineActivity = ActivityIndicator()
    private let timelineGenerator: TimelineGenerator
    private var disposeBag = DisposeBag()
    
    // MARK: Initializer
    init(loggingService: LoggingService,
         timeService: TimeService,
         metricsService: MetricsService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         smartGuessService : SmartGuessService,
         selectedDateService : SelectedDateService,
         settingsService : SettingsService,
         appLifecycleService: AppLifecycleService,
         locationService: LocationService,
         trackEventService: TrackEventService,
         motionService: MotionService,
         goalService: GoalService)
    {
        self.loggingService = loggingService
        self.timeService = timeService
        self.metricsService = metricsService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.smartGuessService = smartGuessService
        self.settingsService = settingsService
        self.appLifecycleService = appLifecycleService
        self.locationService = locationService
        self.trackEventService = trackEventService
        self.motionService = motionService
        self.goalService = goalService
        
        timelineGenerator = TimelineGenerator(loggingService: loggingService,
                                              trackEventService: trackEventService,
                                              smartGuessService: smartGuessService,
                                              timeService: timeService,
                                              timeSlotService: timeSlotService,
                                              metricsService: metricsService,
                                              settingsService: settingsService,
                                              motionService: motionService)
        
        isEditingObservable = editStateService.isEditingObservable
        dateObservable = selectedDateService.currentlySelectedDateObservable
        beganEditingObservable = editStateService.beganEditingObservable
        
        categoryProvider = DefaultCategoryProvider(timeSlotService: timeSlotService)

        super.init()
        
        appLifecycleService.movedToForegroundObservable
            .flatMap { [unowned self] _ -> Observable<Location> in
                if let location = settingsService.lastLocation {
                    return self.didBecomeActive
                        .mapTo(location)
                }
                
                return locationService.currentLocation
                    .subscribeOn(OperationQueueScheduler(operationQueue: OperationQueue()))
                    .do(onNext: settingsService.setLastLocation)
                    .trackActivity(self.locatingActivity)
            }
            .flatMap { [unowned self] _ in
                return self.timelineGenerator.execute()
                    .trackActivity(self.generatingTimelineActivity)
            }
            .subscribe()
            .disposed(by: disposeBag)        

    }
    
    /// - Returns: Current day of a month to put in the calendar button
    var calendarDay : Observable<String>
    {
        return self.appLifecycleService.movedToForegroundObservable
            .startWith(())
            .map { [unowned self] in
                let currentDay = Calendar.current.component(.day, from: self.timeService.now)
                return String(format: "%02d", currentDay)
        }
    }
    
    //MARK: Public Methods
    func notifyEditingEnded() { editStateService.notifyEditingEnded() }

    func addNewSlot(withCategory category: Category)
    {
        guard let _ =
            timeSlotService.addTimeSlot(withStartTime: timeService.now,
                                             category: category,
                                             categoryWasSetByUser: true,
                                             tryUsingLatestLocation: true)
        else { return }
        
        metricsService.log(event: .timeSlotManualCreation(date: timeService.now, category: category))
        metricsService.log(event: .timeSlotCreated(date: timeService.now, category: category, duration: nil))
    }
    
    func markAddGoalAlertShown()
    {
        settingsService.setLastShownAddGoalAlert(timeService.now)
    }
    
    func updateSlotTimelineItem(_ slotTimelineItem: SlotTimelineItem, withCategory category: Category)
    {
        updateTimeSlot(slotTimelineItem.timeSlots, withCategory: category)
        
        editStateService.notifyEditingEnded()
    }
    
    //MARK: Private Methods
    
    private func updateTimeSlot(_ timeSlots: [TimeSlot], withCategory category: Category)
    {
        timeSlotService.update(timeSlots: timeSlots, withCategory: category)
        timeSlots.forEach { (timeSlot) in
            metricsService.log(event: .timeSlotEditing(date: timeService.now, fromCategory: timeSlot.category, toCategory: category, duration: timeSlot.duration))
        }
    }
    
    private func shouldShowLocationPermissionRequest() -> Observable<Bool>
    {
        return Observable.just(!settingsService.hasLocationPermission)
    }
    
    private func shouldShowMotionPermissionRequest() -> Observable<Bool>
    {
        return Observable.just(!settingsService.hasCoreMotionPermission)
    }
    
    private func shouldShowNotificationPermissionRequest() -> Observable<Bool>
    {
        guard !settingsService.userRejectedNotificationPermission &&
            settingsService.shouldAskForNotificationPermission &&
            timeService.now.timeIntervalSince(settingsService.installDate!) >= 24 * 60 * 60 else {
                return Observable.just(false)
        }
        
        return settingsService.hasNotificationPermission.map({ !$0 })
    }
}
