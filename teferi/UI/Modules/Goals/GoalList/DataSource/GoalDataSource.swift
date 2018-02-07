import RxDataSources
import Foundation

struct GoalSection
{
    var items: [Item]
}

extension GoalSection: AnimatableSectionModelType
{
    typealias Item = Goal
    
    init(original: GoalSection, items: [Item])
    {
        self = original
        self.items = items
    }
    
    var identity: String { return "" }
}

extension Goal: IdentifiableType, Equatable
{
    var identity: Date {
        return date
    }
    
    public static func == (lhs: Goal, rhs: Goal) -> Bool
    {
        return lhs.category == rhs.category
            && lhs.date == rhs.date
            && lhs.targetTime == rhs.targetTime
    }
}
