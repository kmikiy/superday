@testable import teferi
import XCTest
import Nimble
import RxTest
import RxSwift

class NavigationViewModelTests : XCTestCase
{
    private var viewModel : NavigationViewModel!
    
    private var timeService : MockTimeService!
    private var feedbackService : MockFeedbackService!
    private var selectedDateService : MockSelectedDateService!
    private var appLifecycleService : MockAppLifecycleService!
    
    private var disposeBag : DisposeBag!
    
    private var scheduler : TestScheduler!
    
    
    override func setUp()
    {
        timeService = MockTimeService()
        feedbackService = MockFeedbackService()
        selectedDateService = MockSelectedDateService()
        appLifecycleService = MockAppLifecycleService()
        
        disposeBag = DisposeBag()
        
        timeService.mockDate = getDate(withDay: 13)
        
        viewModel = NavigationViewModel(timeService: timeService,
                                             selectedDateService: selectedDateService,
                                             appLifecycleService: appLifecycleService)
        
        scheduler = TestScheduler(initialClock:0)
    }
    
    func testTheTitlePropertyReturnsSuperdayForTheCurrentDate()
    {
        let observer = scheduler.createObserver(String.self)
        viewModel.title
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        let today = timeService.mockDate!
        selectedDateService.currentlySelectedDate = today
        
        expect(observer.events.last!.value.element!).to(equal(L10n.currentDayBarTitle))
    }

    func testTheTitlePropertyReturnsSuperyesterdayForYesterday()
    {
        let observer = scheduler.createObserver(String.self)
        viewModel.title
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        let yesterday = timeService.mockDate!.yesterday
        selectedDateService.currentlySelectedDate = yesterday
    
        expect(observer.events.last!.value.element!).to(equal(L10n.yesterdayBarTitle))
    }
    
    func testTheTitlePropertyReturnsTheFormattedDayAndMonthForOtherDates()
    {
        let observer = scheduler.createObserver(String.self)
        viewModel.title
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        let olderDate = Date().add(days: -2)
        selectedDateService.currentlySelectedDate = olderDate
        
        let formatter = DateFormatter();
        formatter.timeZone = TimeZone.autoupdatingCurrent;
        formatter.dateFormat = "EEE, dd MMM";
        let expectedText = formatter.string(from: olderDate)
        
        expect(observer.events.last!.value.element!).to(equal(expectedText))
    }
    
    
    
    func testTheTitleChangesWhenTheDateChanges()
    {
        let observer = scheduler.createObserver(String.self)
        viewModel.title
            .subscribe(observer)
            .disposed(by: disposeBag)
        
        let today = timeService.mockDate!
        selectedDateService.currentlySelectedDate = today

        appLifecycleService.publish(.movedToBackground)
        timeService.mockDate = today.add(days: 1)
        appLifecycleService.publish(.movedToForeground(withDailyVotingNotificationDate: nil))
        
        expect(observer.events.last!.value.element!).to(equal(L10n.yesterdayBarTitle))
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
