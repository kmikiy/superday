import UIKit

class GoalPresenter : NSObject
{
    private weak var viewController : GoalViewController!
    private let viewModelLocator : ViewModelLocator
    fileprivate var padding : ContainerPadding?
    fileprivate let swipeInteractionController = SwipeInteractionController()
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> GoalViewController
    {
        let presenter = GoalPresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getGoalViewModel()
        
        let viewController = StoryboardScene.Goal.goal.instantiate()
        viewController.inject(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
    
    func showNewGoalUI()
    {
        let topAndBottomPadding = (UIScreen.main.bounds.height - 431) / 2
        padding = ContainerPadding(left: 16, top: topAndBottomPadding, right: 16, bottom: topAndBottomPadding)
        
        let vc = NewGoalPresenter.create(with: viewModelLocator)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        viewController.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
    }
    
    func showEditGoal(withGoal goal: Goal)
    {
        let topAndBottomPadding = (UIScreen.main.bounds.height - 431) / 2
        padding = ContainerPadding(left: 16, top: topAndBottomPadding, right: 16, bottom: topAndBottomPadding)
        
        let vc = NewGoalPresenter.create(with: viewModelLocator, goalToBeEdited: goal)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        viewController.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
    }
}

extension GoalPresenter : UIViewControllerTransitioningDelegate
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
