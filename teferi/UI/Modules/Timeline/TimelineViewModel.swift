import Foundation
import RxSwift

///ViewModel for the TimelineViewController.
class TimelineViewModel
{
    //MARK: Public Properties
    let date : Date
    var timelineItemsObservable : Observable<[TimelineItem]> { return self.timelineItems.asObservable() }

    //MARK: Private Properties
    private var isCurrentDay : Bool
    private let disposeBag = DisposeBag()
    
    private let timeService : TimeService
    private let timeSlotService : TimeSlotService
    private let editStateService : EditStateService
    private let appLifecycleService : AppLifecycleService
    private let loggingService : LoggingService
    private let settingsService : SettingsService
    private let metricsService : MetricsService
    
    private(set) var timelineItems : Variable<[TimelineItem]> = Variable([])
    
    private var dateInsideExpandedTimeline: Date? = nil
    private var manualRefreshSubject = PublishSubject<Void>()
    
    var dailyVotingNotificationObservable : Observable<Date>
    {
        return self.appLifecycleService.startedOnDailyVotingNotificationDateObservable
    }
    
    var didBecomeActiveObservable : Observable<Void>
    {
        return self.appLifecycleService.movedToForegroundObservable
    }
    
    //MARK: Initializers
    init(date completeDate: Date,
         timeService: TimeService,
         timeSlotService: TimeSlotService,
         editStateService: EditStateService,
         appLifecycleService: AppLifecycleService,
         loggingService: LoggingService,
         settingsService: SettingsService,
         metricsService: MetricsService)
    {
        self.timeService = timeService
        self.timeSlotService = timeSlotService
        self.editStateService = editStateService
        self.appLifecycleService = appLifecycleService
        self.loggingService = loggingService
        self.settingsService = settingsService
        self.metricsService = metricsService
        self.date = completeDate.ignoreTimeComponents()
        
        isCurrentDay = timeService.now.ignoreTimeComponents() == date
        
        let timelineObservable = !isCurrentDay ? Observable.empty() : Observable<Int>.timer(1, period: 10, scheduler: MainScheduler.instance).mapTo(())
        
        let newTimeSlotForThisDate = !isCurrentDay ? Observable.empty() : timeSlotService
            .timeSlotCreatedObservable
            .filter(belogsToDate)
            .mapTo(())
        
        let updatedTimeSlotsForThisDate = timeSlotService.timeSlotsUpdatedObservable
            .map(timeSlotsBelogToDate)
            .mapTo(())
        
        let movedToForeground = appLifecycleService
            .movedToForegroundObservable
            .mapTo(())
        
        let refreshObservable =
            Observable.of(newTimeSlotForThisDate, updatedTimeSlotsForThisDate, movedToForeground, manualRefreshSubject.asObservable(), timelineObservable.mapTo(()))
                      .merge()
                      .startWith(()) // This is a hack I can't remove due to something funky with the view controllery lifecycle. We should fix this in the refactor
                
        refreshObservable
            .map(timeSlotsForToday)
            .map(toTimelineItems)
            .bind(to: timelineItems)
            .disposed(by: disposeBag)

    }
    
    //MARK: Public methods
    
    func notifyEditingBegan(point: CGPoint, item: SlotTimelineItem? = nil)
    {
        guard let slotTimelineItem = item else { return }
        
        editStateService
            .notifyEditingBegan(point: point,
                                slotTimelineItem: slotTimelineItem)
    }
    
    func collapseSlots()
    {
        dateInsideExpandedTimeline = nil
        manualRefreshSubject.onNext(())
    }
    
    func expandSlots(item: SlotTimelineItem)
    {
        dateInsideExpandedTimeline = item.timeSlots.first?.startTime
        manualRefreshSubject.onNext(())
    }
    
    func calculateDuration(ofTimeSlot timeSlot: TimeSlot) -> TimeInterval
    {
        return timeSlotService.calculateDuration(ofTimeSlot: timeSlot)
    }
    
    func canShowVotingUI() -> Bool
    {
        return canShowVotingView(forDate: date)
    }
    
    func setVote(vote: Bool)
    {
        settingsService.setVote(forDate: date)
        metricsService.log(event: .timelineVote(date: timeService.now, voteDate: date, vote: vote))
    }
    
    
    //MARK: Private Methods
    private func belogsToDate(timeSlot: TimeSlot) -> Bool
    {
        return timeSlot.belongs(toDate: date)
    }
    
    private func timeSlotsBelogToDate(timeSlots: [TimeSlot]) -> [TimeSlot]
    {
        return timeSlots.belonging(toDate: date)
    }
    
    private func canShowVotingView(forDate date: Date) -> Bool
    {
        guard
            let installDate = settingsService.installDate,
            timeService.now.timeIntervalSince(date) < Constants.sevenDaysInSeconds &&
            ( timeService.now.ignoreTimeComponents() == date.ignoreTimeComponents() ? timeService.now.hour >= Constants.hourToShowDailyVotingUI : true ) &&
            installDate.ignoreTimeComponents() != date.ignoreTimeComponents()
        else { return false }
        
        let alreadyVoted = !settingsService.lastSevenDaysOfVotingHistory().contains(date.ignoreTimeComponents())
        
        return alreadyVoted
    }
    
    private func timeSlotsForToday() -> [TimeSlot]
    {
        return timeSlotService.getTimeSlots(forDay: date)
    }
    
    private func toTimelineItems(fromTimeSlots timeSlots: [TimeSlot]) -> [TimelineItem]
    {
        let timelineItems = timeSlots
            .splitBy { $0.category }
            .reduce([TimelineItem](), { acc, groupedTimeSlots in
     
                if groupedTimeSlots.count > 1 && areExpanded(groupedTimeSlots)
                {
                    return acc + expandedTimelineItems(fromTimeSlots: groupedTimeSlots)
                }
                else
                {
                    let slotTimelineItem = SlotTimelineItem.with(timeSlots: groupedTimeSlots, timeSlotService: timeSlotService)
                    
                    let timelineItem = groupedTimeSlots.first!.category == .commute ?
                        TimelineItem.commuteSlot(item: slotTimelineItem) :
                        TimelineItem.slot(item: slotTimelineItem)
                    
                    return acc + [ timelineItem ]
                }
            })
        
        // Add isLastInPastDay or isRunning to last timeslot of timeline
        if let lastTimelineItem = timelineItems.last, case TimelineItem.slot(let slotTimelineItem) = lastTimelineItem
        {
            return Array(timelineItems.dropLast()) + [TimelineItem.slot(item: slotTimelineItem.withLastTimeSlotFlag(isCurrentDay: isCurrentDay))]
        }
        else
        {
            return timelineItems
        }
    }
    
    private func expandedTimelineItems(fromTimeSlots timeSlots: [TimeSlot]) -> [TimelineItem]
    {
        guard let first = timeSlots.first, let last = timeSlots.last, first.startTime != last.startTime else { return [] }
        let category = first.category
        
        let slotTimelineItem = SlotTimelineItem.with(timeSlots: timeSlots, timeSlotService: timeSlotService)
        
        let titleItem = category == .commute ?
            TimelineItem.expandedCommuteTitle(item: slotTimelineItem) :
            TimelineItem.expandedTitle(item: slotTimelineItem)
        
        let collapseItem = TimelineItem.collapseButton(color: first.category.color)
        
        let items = timeSlots.map { slot -> TimelineItem in
            let slotTimelineItem = SlotTimelineItem.with(timeSlots: [slot], timeSlotService: timeSlotService)
            return TimelineItem.expandedSlot(item: slotTimelineItem, hasSeparator: slot.startTime != last.startTime)
        }
        
        return [titleItem] + items + [collapseItem]
    }
    
    private func isLastInPastDay(_ index: Int, count: Int) -> Bool
    {
        guard !isCurrentDay else { return false }
        
        let isLastEntry = count - 1 == index
        return isLastEntry
    }
    
    private func areExpanded(_ timeSlots:[TimeSlot]) -> Bool
    {
        guard let dateInsideExpandedTimeline = dateInsideExpandedTimeline else { return false }
        
        return timeSlots.index(where: { $0.startTime == dateInsideExpandedTimeline }) != nil
    }
}
