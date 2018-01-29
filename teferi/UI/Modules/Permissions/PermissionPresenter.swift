import UIKit

enum PermissionRequestType
{
    case location
    case motion
    case notification
}

class PermissionPresenter
{
    private weak var viewController : PermissionViewController!
    
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, type:PermissionRequestType) -> PermissionViewController
    {
        let presenter = PermissionPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Main.permission.instantiate()
        let viewModel = permissionViewModel(forType: type, viewModelLocator: viewModelLocator)
        viewController.inject(presenter: presenter, viewModel: viewModel)
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    private static func permissionViewModel(forType type:PermissionRequestType, viewModelLocator:ViewModelLocator) -> PermissionViewModel
    {
        switch type {
        case .motion:
            return viewModelLocator.getMotionPermissionViewModel()
        case .location:
            return viewModelLocator.getLocationPermissionViewModel()
        case .notification:
            return viewModelLocator.getNotificationPermissionViewModel()
        }
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}
