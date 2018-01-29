import Foundation
import RxSwift

class TimeslotDetailPresenter: NSObject
{
    private weak var viewController : TimeslotDetailViewController!
    private let viewModelLocator : ViewModelLocator
    fileprivate var padding : ContainerPadding?
    fileprivate var hasShadow : Bool = false
    fileprivate let swipeInteractionController = SwipeInteractionController()
    
    init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, startDate: Date, isShowingSubSlot: Bool = false, updateStartDateSubject: PublishSubject<Date>? = nil) -> TimeslotDetailViewController
    {
        let presenter = TimeslotDetailPresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getTimeslotDetailViewModel(for: startDate, isShowingSubSlot: isShowingSubSlot, updateStartDateSubject: updateStartDateSubject)
        
        let viewController = StoryboardScene.Main.editTimeslot.instantiate()
        viewController.inject(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
    
    func showEditBreakTime(firstTimeSlot: TimeSlot, secondTimeSlot: TimeSlot, editingStartTime: Bool, updateStartDateSubject: PublishSubject<Date>)
    {
        hasShadow = true
        padding = ContainerPadding(left: 16, top: 48, right: 16, bottom: 16)
        
        let vc = EditTimesPresenter.create(with: viewModelLocator,
                                           firstTimeSlot: firstTimeSlot,
                                           secondTimeSlot: secondTimeSlot,
                                           editingStartTime: editingStartTime,
                                           updateStartDateSubject: updateStartDateSubject)
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        viewController.present(vc, animated: true, completion: nil)
        
        swipeInteractionController.wireToViewController(viewController: vc)
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true)
    }
}

extension TimeslotDetailPresenter : UIViewControllerTransitioningDelegate
{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?
    {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting, containerPadding: padding, hasDimmingView: false, hasShadow: hasShadow)
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
