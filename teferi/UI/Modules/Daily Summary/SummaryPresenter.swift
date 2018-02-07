import UIKit

class SummaryPresenter
{
    private weak var viewController : SummaryViewController!
    
    static func create(with viewModelLocator: ViewModelLocator) -> SummaryViewController
    {
        let presenter = SummaryPresenter()
        
        let viewController = StoryboardScene.DailySummary.summary.instantiate()
        
        viewController.inject(viewModelLocator: viewModelLocator)
        
        presenter.viewController = viewController
        
        return viewController
    }
}
