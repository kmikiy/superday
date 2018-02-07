import CoreLocation
import RxSwift
import RxCocoa
import CoreLocation

extension Reactive where Base: CLLocationManager
{
    public var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>
    {
        return RxCLLocationManagerDelegateProxy.proxy(for: base)
    }
    
    public var didUpdateLocations: Observable<[CLLocation]>
    {
        return RxCLLocationManagerDelegateProxy.proxy(for: base).didUpdateLocationsSubject.asObservable()
    }
    
    public var didFailWithError: Observable<Error>
    {
        return RxCLLocationManagerDelegateProxy.proxy(for: base).didFailWithErrorSubject.asObservable()
    }
    
    public var didChangeAuthorizationStatus: Observable<CLAuthorizationStatus>
    {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didChangeAuthorization:)))
            .map { a in
                let number = try castOrThrow(NSNumber.self, a[1])
                return CLAuthorizationStatus(rawValue: Int32(number.intValue)) ?? .notDetermined
        }
    }
}


fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T
{
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    
    return returnValue
}

fileprivate func castOptionalOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T?
{
    if NSNull().isEqual(object) {
        return nil
    }
    
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    
    return returnValue
}

extension CLLocationManager: HasDelegate
{
    public typealias Delegate = CLLocationManagerDelegate
}

public class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate
{
    
    public init(locationManager: CLLocationManager)
    {
        super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }
    
    public static func registerKnownImplementations()
    {
        self.register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
    }
    
    internal lazy var didUpdateLocationsSubject = PublishSubject<[CLLocation]>()
    internal lazy var didFailWithErrorSubject = PublishSubject<Error>()
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        _forwardToDelegate?.locationManager?(manager, didUpdateLocations: locations)
        didUpdateLocationsSubject.onNext(locations)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        _forwardToDelegate?.locationManager?(manager, didFailWithError: error)
        didFailWithErrorSubject.onNext(error)
    }
    
    deinit
    {
        self.didUpdateLocationsSubject.on(.completed)
        self.didFailWithErrorSubject.on(.completed)
    }
}
