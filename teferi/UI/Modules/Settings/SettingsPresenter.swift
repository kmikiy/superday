import Foundation
import UIKit
import StoreKit

class SettingsPresenter
{
    private weak var viewController : SettingsViewController!
    private let viewModelLocator : ViewModelLocator
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> SettingsViewController
    {
        let presenter = SettingsPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Settings.initialScene.instantiate()
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getSettingsViewModel(forViewController: viewController))

        presenter.viewController = viewController
        
        return viewController
    }
    
    func showHelp()
    {
        UIApplication.shared.open(Constants.helpURL, options: [:], completionHandler: nil)
    }
    
    func requestReview()
    {
        UIApplication.shared.open(Constants.appStoreURL, options: [:], completionHandler: nil)
    }
}
