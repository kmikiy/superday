import Foundation

class EnableNotificationsPresenter
{
    private weak var viewController : EnableNotificationsViewController!
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> EnableNotificationsViewController
    {
        let presenter = EnableNotificationsPresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getEnableNotificationsViewModel()
        
        let viewController = StoryboardScene.Goal.instantiateEnableNotifications()
        viewController.inject(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}
