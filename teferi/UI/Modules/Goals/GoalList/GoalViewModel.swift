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
    var lastGoal: Observable<Goal?> {
        return self.goals.asObservable()
            .map(removePlaceHolders)
            .map({ $0.first })
    }
    
    var suggestionObservable: Observable<String?>
    {
        let movedToForeground = appLifecycleService
            .movedToForegroundObservable
            .mapTo(())
        
        let updatedTimeSlotsForYesterday = timeSlotService.timeSlotsUpdatedObservable
            .mapTo(belongsToYesterday)
            .mapTo(())
        
        return Observable.of(movedToForeground, updatedTimeSlotsForYesterday)
            .merge()
            .filter(suggestionForTodayNotShown)
            .map(yesterdaysGoal)
            .filterNil()
            .map(toFailedGoalSuggestion)
            .do(onNext: { [unowned self] suggestion in
                guard let _ = suggestion else { return }
                self.settingsService.setLastShownGoalSuggestion(self.timeService.now)
            })
    }

    //MARK: Private Properties
    private let disposeBag = DisposeBag()
    private var goals : Variable<[Goal]> = Variable([])
    
    private let timeService : TimeService
    private let settingsService : SettingsService
    private let timeSlotService : TimeSlotService
    private let goalService : GoalService
    private let appLifecycleService : AppLifecycleService
    private let goalHeaderMessageProvider: GoalMessageProvider
    
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
        self.goalHeaderMessageProvider = GoalMessageProvider(timeService: self.timeService, settingsService: self.settingsService)
        
        let newGoalForThisDate = goalService.goalCreatedObservable
            .mapTo(())
        
        let updatedGoalForThisDate = goalService.goalUpdatedObservable
            .mapTo(())
        
        let newTimeSlotForThisDate = timeSlotService
            .timeSlotCreatedObservable
            .filter(timeSlotMatchesDate(date: timeService.now))
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
            .bind(to: goals)
            .disposed(by: disposeBag)
    }
    
    func isCurrentGoal(_ goal: Goal?) -> Bool
    {
        guard let goal = goal else { return false }
        return goal.date.ignoreTimeComponents() == timeService.now.ignoreTimeComponents()
    }
    
    func messageAndCategoryVisibility(forGoal goal: Goal?) -> (message: String?, categoryVisible: Bool, newGoalButtonVisible: Bool)
    {
        return goalHeaderMessageProvider.message(forGoal: goal)
    }
    
    //MARK: Private Methods
    
    private func toTodaysGoal(goals: [Goal]) -> Goal?
    {
        guard let firstGoal = goals.first else { return nil }
        
        if firstGoal.date.ignoreTimeComponents() == self.timeService.now.ignoreTimeComponents() {
            return firstGoal
        }
        
        return nil
    }
    
    private func removePlaceHolders(goals: [Goal]) -> [Goal]
    {
        return goals.filter({ $0.category != .unknown })
    }
    
    /// Adds placeholder goals to the given goals array to fill the dates that did not have any goal.
    /// The placeholder goals have the date of the days that do not have any goal and a category of .unknown
    ///
    /// - Parameter goals: Goals that were set by the user already
    /// - Returns: Goals that have extra placeholder goals for the date that the user did not set a goal
    private func withMissingDateGoals(_ goals: [Goal]) -> [Goal]
    {
        guard let firstGoalAdded = goals.last else { return [] }
        
        let firstDay = firstGoalAdded.date
        let today = timeService.now
        var sourceGoals = goals
        
        var goalsToReturn = [Goal]()
        
        var date = firstDay
        repeat {
            if let last = sourceGoals.last, date.isSameDay(asDate: last.date) {
                sourceGoals = Array(sourceGoals.dropLast())
                goalsToReturn.append(last)
            } else {
                if !date.isSameDay(asDate: today) {
                    goalsToReturn.append(Goal(date: date, category: .unknown, targetTime: 0))
                }
            }
            date = date.add(days: 1)
        } while !date.isSameDay(asDate: today.tomorrow)
        
        return goalsToReturn.reversed()
    }
    
    private func getGoals() -> [Goal]
    {
        guard let installDate = settingsService.installDate else { return [] }
        
        return goalService.getGoals(sinceDaysAgo: installDate.differenceInDays(toDate: timeService.now))
    }
    
    private func yesterdaysGoal() -> Goal?
    {
        return goalService.getGoals(sinceDaysAgo: 1)
            .filter{ [unowned self] in $0.date.ignoreTimeComponents() == self.timeService.now.yesterday.ignoreTimeComponents() }
            .first
    }
    
    private func timeSlotMatchesDate(date: Date) -> (TimeSlot) -> Bool
    {
        return { timeSlot in
            return timeSlot.startTime.ignoreTimeComponents() == date.ignoreTimeComponents()
        }
    }
    
    private func belongsToThisDate(_ timeSlots: [TimeSlot]) -> [TimeSlot]
    {
        return timeSlots.filter(timeSlotMatchesDate(date:timeService.now))
    }
    
    private func belongsToYesterday(_ timeSlots: [TimeSlot]) -> [TimeSlot]
    {
        return timeSlots.filter(timeSlotMatchesDate(date: timeService.now.yesterday))
    }
    
    private func suggestionForTodayNotShown() -> Bool
    {
        guard let lastSuggestionShownDate = settingsService.lastShownGoalSuggestion else { return true }
        return lastSuggestionShownDate.ignoreTimeComponents() != timeService.now.ignoreTimeComponents()
    }
    
    private func toFailedGoalSuggestion(goal: Goal) -> String?
    {
        if goal.percentageCompleted > 1 { return nil }
        
        if goal.targetTime >= 2 * 60 * 60 {
            let halfTime = formatedElapsedTimeLongText(for: goal.targetTime / 2)
            return arc4random_uniform(2) == 0 ? L10n.goalSuggestion1(halfTime) :  L10n.goalSuggestion2(halfTime)
        }
        
        let yesterday = timeService.now.yesterday
        let earlyMatchingTimeSlots = timeSlotService.getTimeSlots(forDay: yesterday)
            .filter { timeSlot in
                return timeSlot.startTime.ignoreDateComponents() < Date.createTime(hour: 9, minute: 30)
            }
            .filter { timeSlot in
                return timeSlot.category == Category.commute || timeSlot.category == Category.fitness || timeSlot.category == goal.category
        }
        
        if earlyMatchingTimeSlots.count > 0 {
            return nil
        }
        
        return arc4random_uniform(2) == 1 ? L10n.goalSuggestion3 :  L10n.goalSuggestion4
    }
}
