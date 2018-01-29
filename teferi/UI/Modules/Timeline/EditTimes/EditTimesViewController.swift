import UIKit
import RxSwift

class EditTimesViewController: UIViewController
{
    let minSlotHeight: CGFloat = 36
    
    private var presenter : EditTimesPresenter!
    private var viewModel : EditTimesViewModel!
    
    @IBOutlet weak var handle: HandleView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var topSlot: SlotView!
    @IBOutlet weak var bottomSlot: SlotView!
    
    private var totalHeight: CGFloat = 0
    private var disposeBag = DisposeBag()
    
    func inject(presenter: EditTimesPresenter, viewModel: EditTimesViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
        
    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.clipsToBounds = true
        view.backgroundColor = UIColor.white
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(EditTimesViewController.moveHandle(recognizer:)))
        handle.addGestureRecognizer(recognizer)
        
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        if totalHeight == 0 {
            totalHeight = topSlot.frame.height + bottomSlot.frame.height - minSlotHeight * 2
            topConstraint.constant = viewModel.initialSlotRatio * totalHeight + minSlotHeight
            view.setNeedsLayout()
        }
    }
    
    private func bindViewModel()
    {
        Observable.of(viewModel.topSlotObservable, viewModel.bottomSlotObservable)
            .merge()
            .filter({ $0 == nil }).mapTo(())
            .subscribe(onNext: presenter.dismiss)
            .addDisposableTo(disposeBag)
        
        viewModel.topSlotObservable
            .filterNil()
            .subscribe(onNext: { [unowned self] slot in
                self.topSlot.category = slot.category
                self.topSlot.startTime = slot.startTime
                self.topSlot.duration = slot.duration
            })
            .addDisposableTo(disposeBag)
        
        viewModel.bottomSlotObservable
            .filterNil()
            .subscribe(onNext: { [unowned self] slot in
                self.bottomSlot.category = slot.category
                self.bottomSlot.startTime = slot.startTime
                self.bottomSlot.duration = slot.duration
            })
            .addDisposableTo(disposeBag)
        
        handle.color = viewModel.selectedSlotCategory.color
    }
    
    @objc func moveHandle(recognizer: UIPanGestureRecognizer)
    {
        let yTranslation = recognizer.translation(in: view).y
        topConstraint.constant += yTranslation
        
        if topConstraint.constant < minSlotHeight {
            topConstraint.constant = minSlotHeight
        }
        
        if topConstraint.constant > totalHeight + minSlotHeight {
            topConstraint.constant = totalHeight + minSlotHeight
        }
        
        view.setNeedsLayout()
        viewModel.updateTimes(topPercentage: Double((topConstraint.constant - minSlotHeight) / totalHeight))
        
        recognizer.setTranslation(CGPoint.zero, in: view)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any)
    {
        viewModel.saveTimes()
        presenter.dismiss()
    }
}
