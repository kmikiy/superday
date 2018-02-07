import Foundation
import XCTest
import RxSwift
import RxTest
import Nimble
@testable import teferi

class TimelineViewModelTests : XCTestCase
{
    private var disposeBag : DisposeBag = DisposeBag()
    private var viewModel : TimelineViewModel!
    
    private var timeService : MockTimeService!
    private var metricsService : MockMetricsService!
    private var locationService : MockLocationService!
    private var timeSlotService : MockTimeSlotService!
    private var editStateService : MockEditStateService!
    private var appLifecycleService : MockAppLifecycleService!
    private var loggingService : MockLoggingService!
    private var settingsService : MockSettingsService!
    
    private var observer: TestableObserver<[TimelineItem]>!
    private var scheduler:TestScheduler!
    
    override func setUp()
    {
        disposeBag = DisposeBag()
        timeService = MockTimeService()
        metricsService = MockMetricsService()
        locationService = MockLocationService()
        editStateService = MockEditStateService()
        appLifecycleService = MockAppLifecycleService()
        timeSlotService = MockTimeSlotService(timeService: timeService,
                                                   locationService: locationService)
        loggingService = MockLoggingService()
        settingsService = MockSettingsService()
        
        viewModel = TimelineViewModel(date: Date(),
                                           timeService: timeService,
                                           timeSlotService: timeSlotService,
                                           editStateService: editStateService,
                                           appLifecycleService: appLifecycleService,
                                           loggingService: loggingService,
                                           settingsService: settingsService,
                                           metricsService: metricsService)
        
        scheduler = TestScheduler(initialClock:0)
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .disposed(by: disposeBag)
    }
    
    override func tearDown()
    {
        disposeBag = DisposeBag()
    }
    
    func testViewModelsForTheOlderDaysDoNotSubscribeForTimeSlotUpdates()
    {
        let newMockTimeSlotService = MockTimeSlotService(timeService: timeService,
                                                         locationService: locationService)
        _ = TimelineViewModel(date: Date().yesterday,
                              timeService: timeService,
                              timeSlotService: newMockTimeSlotService,
                              editStateService: editStateService,
                              appLifecycleService: appLifecycleService,
                              loggingService: loggingService,
                              settingsService: settingsService,
                              metricsService: metricsService)
        
        expect(newMockTimeSlotService.didSubscribe).to(beFalse())
    }
    
    func testTheNewlyAddedSlotHasNoEndTime()
    {
        addTimeSlot()
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!.slotTimelineItem!

        expect(lastItem.endTime).to(beNil())
    }
    
    func testTheAddNewSlotsMethodEndsThePreviousTimeSlot()
    {
        addTimeSlot()
        addTimeSlot(minutesAfterNoon: 100, category: .leisure)

        let lastEvent = observer.events.last!
        let firstItem = lastEvent.value.element!.first!.slotTimelineItem!
        
        expect(firstItem.endTime).toNot(beNil())
    }
    
    func testViewModelNeverMergesUnknownTimeSlots()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .unknown)
        addTimeSlot(minutesAfterNoon: 3, category: .unknown)
        
        let lastEvent = observer.events.last!
        let lastItem = lastEvent.value.element!.last!.slotTimelineItem!
        
        expect(lastItem.shouldDisplayCategoryName).to(beTrue())
    }
    
    func testViewModelForwardsUpdatesOnCategoriesForToday()
    {
        let ts = addTimeSlot(minutesAfterNoon: 0)
        addTimeSlot(minutesAfterNoon: 3)
        
        timeSlotService.update(timeSlots: [ts], withCategory: .family)
        
        let slotTimelineItems = observer.events.last!.value.element!.flatMap({ $0.slotTimelineItem })
        
        expect(self.observer.events.count).to(equal(4)) //3 events plus initial one
        expect(slotTimelineItems[0].category).to(equal(Category.family))
    }
    
    func testViewModelForwardsUpdatesOnCategoriesForDaysBeforeToday()
    {
        let minutesOffset:TimeInterval = -3*24*60
        
        let ts = addTimeSlot(minutesAfterNoon: Int(0 + minutesOffset))
        addTimeSlot(minutesAfterNoon: Int(3 + minutesOffset))

        
        viewModel = TimelineViewModel(date: Date().addingTimeInterval(minutesOffset*60).ignoreTimeComponents(),
                                           timeService: timeService,
                                           timeSlotService: timeSlotService,
                                           editStateService: editStateService,
                                           appLifecycleService: appLifecycleService,
                                           loggingService: loggingService,
                                           settingsService: settingsService,
                                           metricsService: metricsService)
        
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        
        timeSlotService.update(timeSlots: [ts], withCategory: .leisure)
        
        let slotTimelineItems = observer.events.last!.value.element!.flatMap({ $0.slotTimelineItem })
        
        expect(self.observer.events.count).to(equal(2)) //initial one plus update one
        expect(slotTimelineItems[0].category).to(equal(Category.leisure))
    }
    
    func testViewModelForwardsTimeSlotCreationForToday()
    {
        addTimeSlot(minutesAfterNoon: Int(20))
        expect(self.observer.events.count).to(equal(2)) //initial one plus new timeslot
    }
    
    func testViewModelDoesntForwardTimeSlotCreationForDaysBeforeToday()
    {
        let dateOffset:TimeInterval = -3*24*60*60
        
        viewModel = TimelineViewModel(date: Date().addingTimeInterval(dateOffset).ignoreTimeComponents(),
                                           timeService: timeService,
                                           timeSlotService: timeSlotService,
                                           editStateService: editStateService,
                                           appLifecycleService: appLifecycleService,
                                           loggingService: loggingService,
                                           settingsService: settingsService,
                                           metricsService: metricsService)
        
        observer = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        addTimeSlot(minutesAfterNoon: Int(20))
        expect(self.observer.events.count).to(equal(1)) //just initial one
    }
    
    func testNotifyEditingBeganGetsTheCorrectlyIndexedItem()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .work)
        addTimeSlot(minutesAfterNoon: 3, category: .leisure)
        addTimeSlot(minutesAfterNoon: 5, category: .family)
        addTimeSlot(minutesAfterNoon: 8, category: .work)
        
        let observer:TestableObserver<(CGPoint, SlotTimelineItem)> = scheduler.createObserver((CGPoint, SlotTimelineItem).self)
        editStateService.beganEditingObservable
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        let timelineItemsObserver: TestableObserver<[TimelineItem]> = scheduler.createObserver([TimelineItem].self)
        viewModel.timelineItemsObservable
            .subscribe(timelineItemsObserver)
            .disposed(by: disposeBag)
        
        let items = timelineItemsObserver.events.last!.value.element!.flatMap({ $0.slotTimelineItem })
        
        viewModel.notifyEditingBegan(point: .zero, item: items[2])
        expect(observer.events.last!.value.element!.1.startTime).to(equal(Date.noon.addingTimeInterval(TimeInterval(5 * 60))))
    }
    
    func testFetchesTimeslotsWhenAppWakesUp()
    {
        let oldCount = observer.events.count
        appLifecycleService.publish(.movedToForeground(withDailyVotingNotificationDate: nil))
        expect(self.observer.events.count).to(equal(oldCount + 1))
    }
    
    func testConsecutiveTimeSlotsWithSameCategoryShouldGenerateOneTimelineItem()
    {
        addTimeSlot(minutesAfterNoon: 0, category: .leisure)
        addTimeSlot(minutesAfterNoon: 30, category: .leisure)
        addTimeSlot(minutesAfterNoon: 60, category: .work)
        addTimeSlot(minutesAfterNoon: 90, category: .work)
        
        let lastEvent = observer.events.last!
        let items = lastEvent.value.element!
        
        expect(items.count).to(equal(2))
    }
    
    func testVotesAreLoggedToFabric()
    {
        viewModel.setVote(vote: true)
        
        expect(self.metricsService.didLog(event: .timelineVote(date: self.timeService.now, voteDate: self.viewModel.date, vote: true))).to(beTrue())
    }
    
    @discardableResult private func addTimeSlot(minutesAfterNoon: Int = 0, category : teferi.Category = .work) -> TimeSlot
    {
        let noon = Date.noon
        
        return timeSlotService.addTimeSlot(withStartTime: noon.addingTimeInterval(TimeInterval(minutesAfterNoon * 60)),
                                                category: category,
                                                categoryWasSetByUser: false,
                                                tryUsingLatestLocation: false)!
    }
}

extension TimelineItem
{
    var slotTimelineItem: SlotTimelineItem?
    {
        switch self {
        case .slot(let item),
             .commuteSlot(let item),
             .expandedCommuteTitle(let item),
             .expandedTitle(let item),
             .expandedSlot(let item, _):
            return item
        case .collapseButton(_):
            return nil
        }
    }
}
