import XCTest
import Nimble
import HealthKit
@testable import teferi

class HealthKitTemporaryTimeLineGeneratorTest: XCTestCase
{
    private typealias HKSampleTuple = (start: Double, end: Double, identifier: String, quantity: Int)
    private typealias TempTimeSlotTuple = (start: Double, category: teferi.Category)
    
    private let startData = Date().ignoreTimeComponents()
    
    private var trackEventService : MockTrackEventService!
    private var healthKitTemporaryTimelineGenerator : HealthKitTemporaryTimeLineGenerator!
    
    override func setUp()
    {
        
        self.trackEventService = MockTrackEventService()
        self.healthKitTemporaryTimelineGenerator = HealthKitTemporaryTimeLineGenerator(trackEventService: trackEventService)
    }
    
    func testExtraUnknownTemporaryTimeslotIsAddedInTheEnd()
    {
        trackEventService.mockEvents = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0)].map(toTrackEvent)
        
        let expectedResult = [(start: 00, category: .commute),
                              (start: 10, category: .unknown)].map(toTempTimeSlot)
        
        let generatedTimeslots = self.healthKitTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testContinuesTimeslotsFromSameCategoryAreMergedIntoOneTemporaryTimeslot()
    {
        trackEventService.mockEvents = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                        (start: 10, end: 20, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                        (start: 20, end: 23, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0),
                                        (start: 23, end: 25, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 0)].map(toTrackEvent)
        
        let expectedResult = [(start: 0, category: .commute),
                              (start: 25, category: .unknown)].map(toTempTimeSlot)
        
        let generatedTimeslots = self.healthKitTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))

        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testContinuesTimeslotsFromDifferentCategoriesAreMergedIntoSeparateTemporaryTimeslot()
    {
        trackEventService.mockEvents = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                        (start: 10, end: 20, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                        (start: 20, end: 30, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                        (start: 30, end: 40, identifier: HKQuantityTypeIdentifier.distanceCycling.rawValue, quantity: 200),
                                        (start: 40, end: 50, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 50, end: 60, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 60, end: 70, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 70, end: 80, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200)].map(toTrackEvent)
        
        let expectedResult = [(start: 00, category: .commute),
                              (start: 40, category: .commute),
                              (start: 80, category: .unknown)].map(toTempTimeSlot)
        
        let generatedTimeslots = self.healthKitTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    func testCommuteIsDetectedInsideContinuesWalkingAndRunningSamples()
    {
        trackEventService.mockEvents = [(start: 00, end: 10, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 100),
                                        (start: 10, end: 15, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 50),
                                        (start: 15, end: 20, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 20, end: 30, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 250),
                                        (start: 30, end: 40, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 2),
                                        (start: 40, end: 50, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 50, end: 60, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 60, end: 70, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 20),
                                        (start: 70, end: 80, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 50),
                                        (start: 80, end: 90, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 90, end: 100, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 200),
                                        (start: 100, end: 110, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 4),
                                        (start: 110, end: 120, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 5),
                                        (start: 120, end: 130, identifier: HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, quantity: 6)].map(toTrackEvent)
        
        let expectedResult = [(start: 00, category: .unknown),
                              (start: 15, category: .commute),
                              (start: 30, category: .unknown),
                              (start: 40, category: .commute),
                              (start: 60, category: .unknown),
                              (start: 80, category: .commute),
                              (start: 100, category: .unknown),
                              (start: 130, category: .unknown)].map(toTempTimeSlot)
        
        let generatedTimeslots = self.healthKitTemporaryTimelineGenerator.generateTemporaryTimeline()
        
        expect(generatedTimeslots.count).to(equal(expectedResult.count))
        
        generatedTimeslots
            .enumerated()
            .forEach { i, actualTimeSlot in compare(timeSlot: actualTimeSlot, to: expectedResult[i]) }
    }
    
    // MARK: - Helper
    private func toTempTimeSlot(tuple: TempTimeSlotTuple) -> TemporaryTimeSlot
    {
        return TemporaryTimeSlot(start: date(tuple.start), smartGuess: nil, category: tuple.category, location: nil)
    }
    
    private func toTrackEvent(tuple: HKSampleTuple) -> TrackEvent
    {
        var healthSample : HealthSample?
        
        switch tuple.identifier {
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue, HKQuantityTypeIdentifier.distanceCycling.rawValue:
            healthSample = HealthSample(withIdentifier: tuple.identifier, startTime: date(tuple.start), endTime: date(tuple.end), value: HKQuantity(unit: HKUnit.meter(), doubleValue: Double(tuple.quantity)))
        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            healthSample = HealthSample(withIdentifier: tuple.identifier, startTime: date(tuple.start), endTime: date(tuple.end), value: nil)
        default:
            break
        }
        
        return TrackEvent.newHealthSample(sample: healthSample!)
    }
    
    private func date(_ timeInterval: TimeInterval) -> Date
    {
        return startData.addingTimeInterval(timeInterval * 60)
    }
    
    private func compare(timeSlot actualTimeSlot: TemporaryTimeSlot, to expectedTimeSlot: TemporaryTimeSlot)
    {
        expect(actualTimeSlot.start).to(equal(expectedTimeSlot.start))
        expect(actualTimeSlot.category).to(equal(expectedTimeSlot.category))
    }
}
