import UIKit
import RxSwift
import Foundation

class PermissionViewController : UIViewController
{
    // MARK: Private Properties
    
    private var viewModel : PermissionViewModel!
    private var presenter : PermissionPresenter!
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet private weak var titleLabel : UILabel!
    @IBOutlet private weak var descriptionLabel : UILabel!
    @IBOutlet private weak var secondaryButton : UIButton!
    @IBOutlet private weak var enableButton : UIButton!
    @IBOutlet private weak var mainButtonBottomConstraint : NSLayoutConstraint!
    @IBOutlet private weak var imageView: UIImageView!
    
    // MARK: Public Methods
    func inject(presenter:PermissionPresenter, viewModel: PermissionViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)

        enableButton.rx.tap
            .flatMapLatest(getUserPermission)
            .subscribe(onNext: onPermissionGiven)
            .disposed(by: disposeBag)
        
        secondaryButton
            .rx.tap
            .subscribe(onNext: onSecondaryButtonTapped)
            .disposed(by: disposeBag)
        
        initializeBindings()
    }
    
    // MARK: Private Methods
    
    private func initializeBindings()
    {
        viewModel.hideOverlayObservable
            .subscribe(onNext: hideOverlay)
            .disposed(by: disposeBag)
        
        titleLabel.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText
        enableButton.setTitle(viewModel.enableButtonTitle, for: .normal)
        secondaryButton.isHidden = viewModel.isSecondaryButtonHidden
        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        imageView.image = viewModel.image
        
        mainButtonBottomConstraint.constant = viewModel.isSecondaryButtonHidden ? 32 : 70
        view.setNeedsLayout()
    }
    
    private func getUserPermission() -> Observable<Void>
    {
        viewModel.getUserPermission()
        return viewModel.permissionGivenObservable
    }
    
    private func onPermissionGiven()
    {
        viewModel.permissionGiven()
    }
    
    private func onSecondaryButtonTapped()
    {
        viewModel.secondaryAction()
        hideOverlay()
    }
    
    private func hideOverlay()
    {
        presenter.dismiss()
    }
}
