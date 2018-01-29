import UIKit

class MainPresenter : NSObject
{
    private weak var viewController : MainViewController!
    private let viewModelLocator : ViewModelLocator
    private var calendarViewController : CalendarViewController? = nil
    
    fileprivate let swipeInteractionController = SwipeInteractionController()
    fileprivate var padding : ContainerPadding?
    
    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator) -> MainViewController
    {
        let presenter = MainPresenter(viewModelLocator: viewModelLocator)
        
        let viewController = StoryboardScene.Main.main.instantiate()
        viewController.inject(presenter: presenter, viewModel: viewModelLocator.getMainViewModel())
        
        presenter.viewController = viewController
        
        return viewController
    }
    
    func showPermissionController(type: PermissionRequestType)
    {
        let vc = PermissionPresenter.create(with: viewModelLocator, type: type)
        vc.modalPresentationStyle = .custom
        vc.modalTransitionStyle = .crossDissolve
        viewController.present(vc, animated: true)
    }
    
    func showCMAccessForExistingUsers()
    {
        padding = ContainerPadding(left: 16, top: 16, right: 16, bottom: 16)
        
        let vc = CMAccessForExistingUsersPresenter.create(with: viewModelLocator)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        viewController.present(vc, animated: true, completion: nil)
    }
    
    func showWeeklyRating(fromDate: Date, toDate: Date)
    {
        padding = ContainerPadding(left: 16, top: 56, right: 16, bottom: 56)
        
        let vc = RatingPresenter.create(with: viewModelLocator, start: fromDate, end: toDate)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        viewController.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
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
    
    func setupPagerViewController(vc:PagerViewController) -> PagerViewController
    {
        return PagerPresenter.create(with: viewModelLocator, fromViewController: vc)
    }
    
    func toggleCalendar()
    {
        if let _ = calendarViewController {
            hideCalendar()
        } else {
            showCalendar()
        }
    }
    
    private func showCalendar()
    {
        calendarViewController = CalendarPresenter.create(with: viewModelLocator, dismissCallback: didHideCalendar)
        viewController.addChildViewController(calendarViewController!)
        viewController.view.addSubview(calendarViewController!.view)
        calendarViewController!.didMove(toParentViewController: viewController)
    }
    
    private func hideCalendar()
    {
        calendarViewController?.hide()
    }
    
    private func didHideCalendar()
    {
        guard let calendar = calendarViewController else { return }
        
        calendar.willMove(toParentViewController: nil)
        calendar.view.removeFromSuperview()
        calendar.removeFromParentViewController()
        
        calendarViewController = nil
    }
}

extension MainPresenter : UIViewControllerTransitioningDelegate
{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?
    {
        if presented is RatingViewController || presented is NewGoalViewController
        {
            return ModalPresentationController(presentedViewController: presented, presenting: presenting, containerPadding: padding)
        }
        else if presented is CMAccessForExistingUsersViewController
        {
            return ModalPresentationController(presentedViewController: presented, presenting: presenting, containerPadding: padding, canBeDismissedByUser: false)
        }
        
        return nil
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        guard
            presented is RatingViewController ||
            presented is CMAccessForExistingUsersViewController ||
            presented is NewGoalViewController
        else { return nil }
        return FromBottomTransition(presenting:true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        guard
            dismissed is RatingViewController ||
            dismissed is CMAccessForExistingUsersViewController ||
            dismissed is NewGoalViewController
        else { return nil }
        return FromBottomTransition(presenting:false)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return swipeInteractionController.interactionInProgress ? swipeInteractionController : nil
    }
}
