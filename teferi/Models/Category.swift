import UIKit

enum Category : String
{
    case commute
    case work
    case food
    case leisure
    case family
    case shopping
    case friends
    case hobby
    case household
    case fitness
    case kids
    case school
    case sleep
    case unknown

    //MARK: Properties
        
    private typealias CategoryData = (description: String, color: UIColor, icon: ImageAsset)
        
    private var attributes : CategoryData
    {
        switch self
        {
        case .commute:
            return (description: L10n.commute, color: UIColor.commute, icon: Asset.icCommuteIcon)
        case .work:
            return (description: L10n.work, color: UIColor.work, icon: Asset.icWorkIcon)
        case .food:
            return (description: L10n.food, color: UIColor.food, icon: Asset.icFoodIcon)
        case .leisure:
            return (description: L10n.leisure, color: UIColor.leisure, icon: Asset.icLeisureIcon)
        case .family:
            return (description: L10n.family, color: UIColor.family, icon: Asset.icFamilyIcon)
        case .shopping:
            return (description: L10n.shopping, color: UIColor.shopping, icon: Asset.icShoppingIcon)
        case .friends:
            return (description: L10n.friends, color: UIColor.friends, icon: Asset.icFriendsIcon)
        case .hobby:
            return (description: L10n.hobby, color: UIColor.hobby, icon: Asset.icHobbyIcon)
        case .household:
            return (description: L10n.household, color: UIColor.household, icon: Asset.icHouseholdIcon)
        case .fitness:
            return (description: L10n.fitness, color: UIColor.fitness, icon: Asset.icFitnessIcon)
        case .kids:
            return (description: L10n.kids, color: UIColor.kids, icon: Asset.icKidsIcon)
        case .school:
            return (description: L10n.school, color: UIColor.school, icon: Asset.icSchoolIcon)
        case .sleep:
            return (description: L10n.sleep, color: UIColor.sleep, icon: Asset.icSleepIcon)
        case .unknown:
            return (description: L10n.unknown, color: UIColor.unknown, icon: Asset.icUnknownIcon)
        }
    }
    
    /// Get all categories
    static let all : [Category] = [ .commute, .work, .food, .leisure, .family, .shopping, .friends, .hobby, .household, .fitness, .kids, .school, .sleep, .unknown ]
    
    /// Get the Color associated with the category.
    var color : UIColor
    {
        return self.attributes.color
    }
    
    /// Get the Asset for the category.
    var icon : ImageAsset
    {
        return self.attributes.icon
    }
    
    /// Get the Localised name for the category.
    var description : String
    {
        return self.attributes.description
    }
}
