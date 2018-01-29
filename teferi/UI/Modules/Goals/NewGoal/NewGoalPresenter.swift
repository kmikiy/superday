import Foundation
import UIKit

class NewGoalPresenter: NSObject
{
    private weak var viewController : NewGoalViewController!
    private let viewModelLocator : ViewModelLocator
    fileprivate var padding : ContainerPadding?
    fileprivate let swipeInteractionController = SwipeInteractionController()

    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, goalToBeEdited: Goal? = nil) -> NewGoalViewController
    {
        let presenter = NewGoalPresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getNewGoalViewModel(goalToBeEdited: goalToBeEdited)
        
        let viewController = StoryboardScene.Goal.newGoal.instantiate()
        viewController.inject(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss(showEnableNotifications: Bool = false)
    {
        let parentViewController = viewController.presentingViewController
        viewController.dismiss(animated: true) { [unowned self] in
            if showEnableNotifications {
                self.showEnableNotificationsUI(inViewController: parentViewController)
            }
        }
    }
    
    private func showEnableNotificationsUI(inViewController parentViewController: UIViewController?)
    {
        guard let parentViewController = parentViewController else { return }
        let topAndBottomPadding = (UIScreen.main.bounds.height - 278) / 2
        padding = ContainerPadding(left: 16, top: topAndBottomPadding, right: 16, bottom: topAndBottomPadding)
        
        let vc = EnableNotificationsPresenter.create(with: viewModelLocator)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        parentViewController.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
    }
}


extension NewGoalPresenter : UIViewControllerTransitioningDelegate
{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?
    {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting, containerPadding: padding)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return FromBottomTransition(presenting:true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return FromBottomTransition(presenting:false)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return swipeInteractionController.interactionInProgress ? swipeInteractionController : nil
    }
}
