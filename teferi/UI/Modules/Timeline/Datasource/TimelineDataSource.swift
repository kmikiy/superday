import RxDataSources
import Foundation

struct TimelineSection
{
    var items: [Item]
}

extension TimelineSection: AnimatableSectionModelType
{
    typealias Item = TimelineItem
    
    init(original: TimelineSection, items: [Item])
    {
        self = original
        self.items = items
    }
    
    var identity: String { return "" }
}
