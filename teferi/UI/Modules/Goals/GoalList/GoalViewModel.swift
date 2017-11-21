import Foundation
import RxSwift

class GoalViewModel
{
    //MARK: Public Properties
    var goalsObservable: Observable<[Goal]> { return self.goals.asObservable() }
    var todaysGoal: Observable<Goal?> {
        return self.goals.asObservable()
            .map(toTodaysGoal)
    }
    
    //MARK: Private Properties
    private let disposeBag = DisposeBag()
    private var goals : Variable<[Goal]> = Variable([])
    
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let goalService : GoalService
    private let appLifecycleService : AppLifecycleService
    private let goalAchievedMessageProvider: GoalAchievedMessageProvider
    
    //MARK: Initializers
    init(timeService: TimeService,
         settingsService : SettingsService,
         timeSlotService: TimeSlotService,
         goalService: GoalService,
         appLifecycleService: AppLifecycleService)
    {
        self.timeService = timeService
        self.settingsService = settingsService
        self.timeSlotService = timeSlotService
        self.goalService = goalService
        self.appLifecycleService = appLifecycleService
        self.goalAchievedMessageProvider = GoalAchievedMessageProvider(timeService: self.timeService, settingsService: self.settingsService)
        
        
        let newGoalForThisDate = goalService.goalCreatedObservable
            .mapTo(())
        
        let updatedGoalForThisDate = goalService.goalUpdatedObservable
            .mapTo(())
        
        let newTimeSlotForThisDate = timeSlotService
            .timeSlotCreatedObservable
            .filter(timeSlotBelongsToThisDate)
            .mapTo(())
        
        let updatedTimeSlotsForThisDate = timeSlotService.timeSlotsUpdatedObservable
            .mapTo(belongsToThisDate)
            .mapTo(())
        
        let movedToForeground = appLifecycleService
            .movedToForegroundObservable
            .mapTo(())
        
        let refreshObservable =
            Observable.of(newGoalForThisDate, updatedGoalForThisDate, movedToForeground, newTimeSlotForThisDate, updatedTimeSlotsForThisDate)
                .merge()
                .startWith(())
        
        refreshObservable
            .map(getGoals)
            .map(withMissingDateGoals)
            .bindTo(goals)
            .addDisposableTo(disposeBag)
        
    }
    
    func isCurrentGoal(_ goal: Goal?) -> Bool
    {
        guard let goal = goal else { return false }
        return goal.date.ignoreTimeComponents() == timeService.now.ignoreTimeComponents()
    }
    
    func message(forGoal goal: Goal?) -> String?
    {
        guard let goal = goal else { return nil }
        
        return goalAchievedMessageProvider.message(forGoal: goal)
    }
    
    //MARK: Private Methods
    
    private func toTodaysGoal(goals:[Goal]) -> Goal?
    {
        guard let firstGoal = goals.first else { return nil }
        if firstGoal.date.ignoreTimeComponents() == self.timeService.now.ignoreTimeComponents() {
            return firstGoal
        }
        
        return nil
    }
    
    /// Adds placeholder goals to the given goals array to fill the dates that did not have any goal.
    /// The placeholder goals have the date of the days that do not have any goal and a category of .unknown
    ///
    /// - Parameter goals: Goals that were set by the user already
    /// - Returns: Goals that have extra placeholder goals for the date that the user did not set a goal
    private func withMissingDateGoals(_ goals: [Goal]) -> [Goal]
    {
        guard goals.count > 0 else { return [] }
        
        var goalsToReturn = [Goal]()
        
        for goal in goals
        {
            if goalsToReturn.isEmpty
            {
                if goal.date.differenceInDays(toDate: timeService.now) > 1
                {
                    goalsToReturn.append(contentsOf: placeHolderGoals(fromDate: goal.date.add(days: 1), toDate: timeService.now.add(days: -1)))
                }
                goalsToReturn.append(goal)
                continue
            }
            
            let lastGoal = goalsToReturn.last!
            
            goalsToReturn.append(contentsOf: placeHolderGoals(fromDate: goal.date.add(days: 1), toDate: lastGoal.date.add(days: -1)))

            goalsToReturn.append(goal)
        }
        
        return goalsToReturn
    }
    
    private func placeHolderGoals(fromDate: Date, toDate: Date) -> [Goal]
    {
        guard fromDate != toDate else { return [Goal(date: fromDate, category: .unknown, targetTime: 0)] }
        
        let ascending = fromDate < toDate
        
        let correctFromDate = min(fromDate, toDate)
        let correctToDate = max(fromDate, toDate)
        
        var goalsToReturn = [Goal(date: correctToDate, category: .unknown, targetTime: 0)]
        
        var lastGoal = goalsToReturn.last!
        
        while correctFromDate.differenceInDays(toDate: lastGoal.date) > 0
        {
            goalsToReturn.append(Goal(date: lastGoal.date.add(days: -1), category: .unknown, targetTime: 0))
            lastGoal = goalsToReturn.last!
        }
        
        return ascending ? goalsToReturn : goalsToReturn.reversed()
    }
    
    private func getGoals() -> [Goal]
    {
        return goalService.getGoals(sinceDaysAgo: 15)
    }
    
    private func timeSlotBelongsToThisDate(_ timeSlot: TimeSlot) -> Bool
    {
        return timeSlot.startTime.ignoreTimeComponents() == timeService.now.ignoreTimeComponents()
    }
    
    private func belongsToThisDate(_ timeSlots: [TimeSlot]) -> [TimeSlot]
    {
        return timeSlots.filter(timeSlotBelongsToThisDate(_:))
    }
}
