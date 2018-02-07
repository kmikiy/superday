import UIKit

class RatingPresenter
{
    private weak var viewController : RatingViewController!
    
    static func create(with viewModelLocator: ViewModelLocator,
                       start startDate: Date,
                       end endDate: Date) -> RatingViewController
    {
        let presenter = RatingPresenter()
        
        let viewController = StoryboardScene.Rating.rating.instantiate()
        
        viewController.inject(viewModel: viewModelLocator.getRatingViewModel(start: startDate, end: endDate), presenter: presenter)
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}
