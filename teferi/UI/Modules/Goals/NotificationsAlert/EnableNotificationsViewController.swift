import UIKit
import RxSwift
import RxCocoa

class EnableNotificationsViewController: UIViewController
{
    private var viewModel: EnableNotificationsViewModel!
    private var presenter: EnableNotificationsPresenter!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    func inject(presenter: EnableNotificationsPresenter, viewModel: EnableNotificationsViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        titleLabel.textColor = UIColor.almostBlack
        textLabel.textColor = UIColor.darkGray
        
        textLabel.text = L10n.enableNotificationsMessage
        
        closeButton.rx.tap
            .subscribe(onNext: presenter.dismiss)
            .disposed(by: disposeBag)
        
        button.rx.tap
            .do(onNext: viewModel.getNotificationPermissions)
            .subscribe(onNext: presenter.dismiss)
            .disposed(by: disposeBag)

    }
}
