import Foundation
import RxSwift

class DefaultTrackEventService : TrackEventService
{
    private let disposeBag = DisposeBag()
    private let eventSources : [EventSource]
    private let loggingService : LoggingService
    private let persistencyService : BasePersistencyService<TrackEvent>
    
    // MARK: Initializers
    init(loggingService: LoggingService, persistencyService: BasePersistencyService<TrackEvent>, withEventSources eventSources: EventSource...)
    {
        self.eventSources = eventSources
        self.loggingService = loggingService
        self.persistencyService = persistencyService

        let observables = eventSources.map { $0.eventObservable }
        Observable.from(observables)
            .merge()
            .subscribe(onNext: persistData)
            .disposed(by: disposeBag)
    }
    
    func getEventData<T : EventData>(ofType: T.Type) -> [ T ]
    {
        let predicate = Predicate(parameter: "", equals: String(describing: T.self) as AnyObject)
        
        return persistencyService.get(withPredicate: predicate).flatMap(T.fromTrackEvent)
    }
    
    func clearAllData()
    {
        persistencyService.delete()
    }
    
    private func persistData(event: TrackEvent)
    {
        if persistencyService.create(event) { return }
            
        loggingService.log(withLogLevel: .warning, message: "Failed to log event data \(event)")
    }
}
