import Foundation
import RxSwift

class EditTimesPresenter
{
    private weak var viewController : EditTimesViewController!
    private let viewModelLocator : ViewModelLocator

    private init(viewModelLocator: ViewModelLocator)
    {
        self.viewModelLocator = viewModelLocator
    }
    
    static func create(with viewModelLocator: ViewModelLocator, firstTimeSlot: TimeSlot, secondTimeSlot: TimeSlot, editingStartTime: Bool, updateStartDateSubject: PublishSubject<Date>) -> EditTimesViewController
    {
        let presenter = EditTimesPresenter(viewModelLocator: viewModelLocator)
        let viewModel = viewModelLocator.getEditTimesViewModel(for: firstTimeSlot, secondTimeSlot: secondTimeSlot, editingStartTime: editingStartTime, updateStartDateSubject: updateStartDateSubject)
        
        let viewController = StoryboardScene.Main.editTimes.instantiate()
        viewController.inject(presenter: presenter, viewModel: viewModel)
        presenter.viewController = viewController
        
        return viewController
    }
    
    func dismiss()
    {
        viewController.dismiss(animated: true, completion: nil)
    }
}
