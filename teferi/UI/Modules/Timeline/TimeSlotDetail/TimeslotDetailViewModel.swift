import Foundation
import RxSwift

class TimeslotDetailViewModel
{
    var slotTimelineItemObservable: Observable<SlotTimelineItem?>
    {
        return slotTimelineItemVariable.asObservable()
    }

    let categoryProvider : CategoryProvider
    let timeService: TimeService
    var isShowingSubSlot : Bool
    let updateStartDateSubject : PublishSubject<Date>
    
    private let timeSlotService: TimeSlotService
    private let metricsService: MetricsService
    private let smartGuessService: SmartGuessService
    private var startDate: Date
    
    private let slotTimelineItemVariable = Variable<SlotTimelineItem?>(nil)
    private let disposeBag = DisposeBag()
    
    private var isCurrentDay : Bool
    {
        return timeService.now.ignoreTimeComponents() == startDate.ignoreTimeComponents()
    }
    
    // MARK: - Init
    init(startDate: Date,
         isShowingSubSlot: Bool = false,
         updateStartDateSubject: PublishSubject<Date>?,
         timeSlotService: TimeSlotService,
         metricsService: MetricsService,
         smartGuessService: SmartGuessService,
         timeService: TimeService,
         appLifecycleService: AppLifecycleService)
    {
        self.startDate = startDate
        self.isShowingSubSlot = isShowingSubSlot
        self.updateStartDateSubject = updateStartDateSubject ?? PublishSubject<Date>()
        self.timeSlotService = timeSlotService
        self.metricsService = metricsService
        self.smartGuessService = smartGuessService
        self.timeService = timeService
        self.categoryProvider = DefaultCategoryProvider(timeSlotService: timeSlotService)
        
        self.updateStartDateSubject.asObservable().subscribe(onNext: { [unowned self] (date) in
            self.startDate = date
        }).disposed(by: disposeBag)
        
        let newTimeSlotForThisDate = timeSlotService.timeSlotCreatedObservable
            .filter(belogsToDate)
            .mapTo(())
        
        let updatedTimeSlotsForThisDate = timeSlotService.timeSlotsUpdatedObservable
            .map(timeSlotsBelogToDate)
            .mapTo(())
        
        let movedToForeground = appLifecycleService
            .movedToForegroundObservable
            .mapTo(())
        
        let refreshObservable =
            Observable.of(newTimeSlotForThisDate, updatedTimeSlotsForThisDate, movedToForeground)
                .merge()
                .startWith(()) // This is a hack I can't remove due to something funky with the view controllery lifecycle. We should fix this in the refactor
        
        refreshObservable
            .map(timeSlotToShow)
            .map(toSlotTimelineItem)
            .bind(to: slotTimelineItemVariable)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public methods
    func updateSlotTimelineItem(_ slotTimelineItem: SlotTimelineItem, withCategory category: Category)
    {
        updateTimeSlot(slotTimelineItem.timeSlots, withCategory: category)
    }
    
    func timeSlot(before timeSlot: TimeSlot) -> TimeSlot?
    {
        guard timeSlot.startTime.ignoreDateComponents() != timeSlot.startTime.ignoreTimeComponents().ignoreDateComponents() else { return nil }
        
        let slots = timeSlotService.getTimeSlots(forDay: timeSlot.startTime.ignoreTimeComponents())
        let slotIndex = slots.map{ $0.startTime }.index(of: timeSlot.startTime) ?? 0
        return slots.safeGetElement(at: slotIndex - 1)
    }
    
    func timeSlot(after timeSlot: TimeSlot) -> TimeSlot?
    {
        guard let endTime = timeSlot.endTime, endTime.ignoreDateComponents() != endTime.ignoreTimeComponents().ignoreDateComponents() else { return nil }
        
        let slots = timeSlotService.getTimeSlots(forDay: timeSlot.startTime.ignoreTimeComponents())
        let slotIndex = slots.map{ $0.startTime }.index(of: timeSlot.startTime) ?? 0
        return slots.safeGetElement(at: slotIndex + 1)
    }
    
    // MARK: - Private methods
    private func belogsToDate(timeSlot: TimeSlot) -> Bool
    {
        return timeSlot.belongs(toDate: startDate)
    }
    
    private func timeSlotsBelogToDate(timeSlots: [TimeSlot]) -> [TimeSlot]
    {
        return timeSlots.belonging(toDate: startDate)
    }
    
    private func timeSlotToShow() -> TimeSlot
    {
        return timeSlotService
            .getTimeSlots(forDay: startDate)
            .filter({ $0.startTime == startDate })
            .first!
    }
    
    private func toSlotTimelineItem(fromTimeSlot timeSlot: TimeSlot) -> SlotTimelineItem
    {
        return SlotTimelineItem.with(timeSlots: [timeSlot], timeSlotService: timeSlotService)
    }
    
    private func updateTimeSlot(_ timeSlots: [TimeSlot], withCategory category: Category)
    {
        timeSlotService.update(timeSlots: timeSlots, withCategory: category)
        timeSlots.forEach { (timeSlot) in
            metricsService.log(event: .timeSlotEditing(date: timeService.now, fromCategory: timeSlot.category, toCategory: category, duration: timeSlot.duration))
        }
    }
}
