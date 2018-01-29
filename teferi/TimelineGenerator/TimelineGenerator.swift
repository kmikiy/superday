import Foundation
import RxSwift

class TimelineGenerator
{
    private let eventAnnotator: EventAnnotator
    private let eventsParser: EventsParser
    private let timelineProcessor: TimelineProcessor
    private let smartGuesser: SmartGuesser
    private let persister: Persister
    private let cleaner: Cleaner
    
    private var generator: Observable<[TemporaryTimeSlot]>!
    private var disposeBag = DisposeBag()
    private var returnSubject: PublishSubject<Void> = PublishSubject<Void>()
    
    init(loggingService: LoggingService,
         trackEventService: TrackEventService,
         smartGuessService: SmartGuessService,
         timeService: TimeService,
         timeSlotService: TimeSlotService,
         metricsService: MetricsService,
         settingsService: SettingsService,
         motionService: MotionService)
    {
        eventAnnotator = EventAnnotator(settingsService: settingsService, timeSlotService: timeSlotService, timeService: timeService, trackEventService: trackEventService, motionService: motionService)
        eventsParser = EventsParser()
        timelineProcessor = TimelineProcessor(settingsService: settingsService, timeSlotService: timeSlotService, timeService: timeService)
        smartGuesser = SmartGuesser(smartGuessService: smartGuessService)
        persister = Persister(timeSlotService: timeSlotService, timeService: timeService, metricsService: metricsService)
        cleaner = Cleaner(settingsService: settingsService, trackEventService: trackEventService, timeService: timeService)
    }
    
    func execute() -> Observable<Void>
    {        
        generator = eventAnnotator.annotatedEvents()
            .map(eventsParser.parse)
            .map(toTemporaryTimeslots)
            .map(timelineProcessor.process)
            .map(smartGuesser.run)
            .do(onNext: { [unowned self] slots in
                self.persister.persist(slots: slots)
                self.cleaner.cleanUp(slots: slots)
            })
                
        generator
            .subscribe(
                onNext: { [unowned self] _ in
                    self.returnSubject.onNext(())
            },
                onError: { [unowned self] error in
                    self.returnSubject.onError(error)
            },
                onCompleted: { [unowned self] in
                    self.returnSubject.onCompleted()
            }
            )
            .disposed(by: disposeBag)
        
        return returnSubject
            .observeOn(MainScheduler.instance)
            .asObservable()
    }
    
    private func toTemporaryTimeslots(events: [AnnotatedEvent]) -> [TemporaryTimeSlot]
    {
        return events.map(TemporaryTimeSlot.init)
    }
}
