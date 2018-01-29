import Foundation

class CMAccessForExistingUsersPresenter
{
    private weak var viewController : CMAccessForExistingUsersViewController!
    
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> CMAccessForExistingUsersViewController
    {
        let presenter = CMAccessForExistingUsersPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Main.cmAccessForExistingUsers.instantiate()
        let viewModel = viewModelLocator.getCMAccessForExistingUsersViewModel()
        viewController.inject(presenter: presenter, viewModel: viewModel)
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}
