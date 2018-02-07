import UIKit
import RxSwift

class CMAccessForExistingUsersViewController: UIViewController
{
    // MARK: Private Properties
    private var viewModel : CMAccessForExistingUsersViewModel!
    private var presenter : CMAccessForExistingUsersPresenter!
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet private weak var titleLabel : UILabel!
    @IBOutlet private weak var descriptionLabel : UILabel!
    @IBOutlet private weak var finePrintLabel : UILabel!
    @IBOutlet private weak var enableButton : UIButton!
    @IBOutlet fileprivate weak var stackView: UIStackView!
    
    // MARK: Public Methods
    func inject(presenter: CMAccessForExistingUsersPresenter, viewModel: CMAccessForExistingUsersViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        enableButton.rx.tap
            .subscribe(onNext: getUserPermission)
            .disposed(by: disposeBag)
        
        initializeBindings()
    }
    
    // MARK: Private Methods
    
    private func initializeBindings()
    {
        titleLabel.text = L10n.cmExistingUsersAccessTitle
        descriptionLabel.text = L10n.cmExistingUsersAccessDescription
        finePrintLabel.text = L10n.cmExistingUsersAccessFinePrint
        enableButton.setTitle(L10n.cmExistingUsersAccessButtonTitle, for: .normal)

        view.setNeedsLayout()
    }
    
    func getUserPermission()
    {
        viewModel.hideOverlayObservable
            .subscribe(onNext: hideOverlay)
            .disposed(by: disposeBag)
    }

    private func hideOverlay()
    {
        presenter.dismiss()
    }
}

extension CMAccessForExistingUsersViewController : DesiredHeightProtocol
{
    func height(forWidth width: CGFloat) -> CGFloat
    {
        view.layoutIfNeeded()
        return stackView.frame.height + stackView.frame.origin.y + 24
    }
}
