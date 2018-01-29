import RxSwift
import RxTest
import XCTest
import Nimble
@testable import teferi

class MainViewModelTests : XCTestCase
{
    private var viewModel : MainViewModel!
    private var disposable : Disposable? = nil
    
    private var loggingService: MockLoggingService!
    private var timeService : MockTimeService!
    private var metricsService : MockMetricsService!
    private var feedbackService : MockFeedbackService!
    private var locationService : MockLocationService!
    private var settingsService : MockSettingsService!
    private var timeSlotService : MockTimeSlotService!
    private var editStateService : MockEditStateService!
    private var smartGuessService : MockSmartGuessService!
    private var appLifecycleService : MockAppLifecycleService!
    private var selectedDateService : MockSelectedDateService!
    private var trackEventService: MockTrackEventService!
    private var motionService: MockMotionService!
    private var goalService: MockGoalService!
    
    private var scheduler = TestScheduler(initialClock:0)
    private var dateLabelObserver: TestableObserver<String>!
    private var disposeBag = DisposeBag()
    
    
    override func setUp()
    {
        loggingService = MockLoggingService()
        timeService = MockTimeService()
        metricsService = MockMetricsService()
        locationService = MockLocationService()
        settingsService = MockSettingsService()
        feedbackService = MockFeedbackService()
        editStateService = MockEditStateService()
        smartGuessService = MockSmartGuessService()
        appLifecycleService = MockAppLifecycleService()
        selectedDateService = MockSelectedDateService()
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
        trackEventService = MockTrackEventService()
        motionService = MockMotionService()
        goalService = MockGoalService(timeService: timeService)
        
        viewModel = MainViewModel(loggingService: loggingService,
                                  timeService: timeService,
                                  metricsService: metricsService,
                                  timeSlotService: timeSlotService,
                                  editStateService: editStateService,
                                  smartGuessService: smartGuessService,
                                  selectedDateService: selectedDateService,
                                  settingsService: settingsService,
                                  appLifecycleService: appLifecycleService,
                                  locationService: locationService,
                                  trackEventService: trackEventService,
                                  motionService: motionService,
                                  goalService: goalService)
        
        timeService.mockDate = getDate(withDay: 13)
        dateLabelObserver = scheduler.createObserver(String.self)
        
        viewModel.calendarDay
            .subscribe(dateLabelObserver)
            .disposed(by: disposeBag)
        
    }
    
    override func tearDown()
    {
        disposable?.dispose()
    }
    
    //MARK: Calendar Button Tests
    func testTheCalendarDayAlwaysReturnsTheCurrentDate()
    {
        let dateText = dateLabelObserver.events.last!.value.element!
        
        expect(dateText).to(equal("13"))
    }
    
    func testTheCalendarDayAlwaysHasTwoPositions()
    {
        appLifecycleService.publish(.movedToBackground)
        timeService.mockDate = getDate(withDay: 1)
        appLifecycleService.publish(.movedToForeground(withDailyVotingNotificationDate: nil))
        
        let dateText = dateLabelObserver.events.last!.value.element!
        
        expect(dateText).to(equal("01"))
    }
    
    func testDateLabelChangesIfDateChangesWhileOnBackground()
    {
        appLifecycleService.publish(.movedToBackground)
        timeService.mockDate = getDate(withDay: 14)
        appLifecycleService.publish(.movedToForeground(withDailyVotingNotificationDate: nil))
        
        let dateText = dateLabelObserver.events.last!.value.element!
        
        expect(dateText).to(equal("14"))
    }
    
    //MARK: Slots
    func testTheAddNewSlotsMethodAddsANewSlot()
    {
        var didAdd = false
        
        disposable = timeSlotService.timeSlotCreatedObservable.subscribe(onNext: { _ in didAdd = true })
        viewModel.addNewSlot(withCategory: .commute)
        
        expect(didAdd).to(beTrue())
    }
    
    func testTheAddNewSlotMethodCallsTheMetricsService()
    {
        viewModel.addNewSlot(withCategory: .commute)
        expect(self.metricsService.didLog(event: .timeSlotManualCreation(date: self.timeService.now, category: .commute))).to(beTrue())
    }
    
    func testLocationPermissionShouldNotBeShownIfTheUserHasAlreadyAuthorized()
    {
        settingsService.hasLocationPermission = true
        
        var wouldShow = false
        disposable = viewModel.showPermissionControllerObservable
            .subscribe(onNext:  { _ in wouldShow = true })
        
        expect(wouldShow).to(beFalse())
    }
    
    func testIfLocationPermissionWasNeverShownItNeedsToBeShown()
    {
        settingsService.hasLocationPermission = false
        
        var wouldShow = false
        disposable = viewModel.showPermissionControllerObservable
            .subscribe(onNext: { type in wouldShow = type == .location })
        
        appLifecycleService.publish(.movedToForeground(withDailyVotingNotificationDate: nil))
        
        expect(wouldShow).to(beTrue())
    }
    
    private func addTimeSlot(withCategory category: teferi.Category) -> TimeSlot
    {
        return timeSlotService.addTimeSlot(withStartTime: Date(),
                                                category: category,
                                                categoryWasSetByUser: false,
                                                tryUsingLatestLocation: false)!
    }
    
    private func getDate(withDay day: Int) -> Date
    {
        var dateComponents = DateComponents()
        dateComponents.year = Date().year
        dateComponents.month = 1
        dateComponents.day = day
        
        return Calendar.current.date(from: dateComponents)!
    }
}
