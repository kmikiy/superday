import UIKit
import Foundation
import RxSwift
import RxCocoa
import Crashlytics

class NavigationController: UINavigationController
{
    private var viewModel : NavigationViewModel!
    private var presenter : NavigationPresenter!
    
    private var logoImageView : UIImageView!
    private var titleLabel : UILabel!
    
    private var disposeBag = DisposeBag()
    
    func inject(presenter: NavigationPresenter, viewModel: NavigationViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
        
        bindViewModel()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()

        logoImageView = UIImageView(image: Image(asset: Asset.icSuperday))
        
        titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 60))
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        titleLabel.textColor = Style.Color.offBlack
        
        let crashTaps = UITapGestureRecognizer(target: self, action: #selector(NavigationController.showCrashDialog))
        crashTaps.numberOfTapsRequired = 10
        logoImageView.isUserInteractionEnabled = true
        logoImageView.addGestureRecognizer(crashTaps)
    }
    
    @objc private func showCrashDialog()
    {
        let alert = UIAlertController(title: "Crash the app?", message: "Choose the error to force", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Crash", style: .default, handler: { _ in
            Crashlytics.sharedInstance().crash()
        }))
        alert.addAction(UIAlertAction(title: "Error", style: .default, handler: { _ in
            Crashlytics.sharedInstance().recordError(NSError(domain: "TestError", code: 0))
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func bindViewModel()
    {
        viewModel.title
            .bindTo(titleLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool)
    {
        super.pushViewController(viewController, animated: animated)
        
        setupNavigationBar(for: viewController)
    }
    
    private func setupNavigationBar(for viewController: UIViewController)
    {
        viewController.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(customView: logoImageView),
            .createFixedSpace(of: 18),
            UIBarButtonItem(customView: titleLabel)
        ]
    }
}
