import UIKit
import RxSwift

class OnboardingPage3 : OnboardingPage
{
    private var disposeBag : DisposeBag = DisposeBag()
    @IBOutlet weak var ios11view: UIView!
    @IBOutlet weak var ios10view: UIView!
    @IBOutlet weak var ios11viewYConstraint: NSLayoutConstraint!
    @IBOutlet weak var ios11viewWidthConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder, nextButtonText: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) { //iOS 11 and greater
            ios11view.isHidden = false
            ios10view.isHidden = true
        } else {
            ios11view.isHidden = true
            ios10view.isHidden = false
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let allowAlwaysButtonYOffset: CGFloat = 70 //With current alert text
        let alertDialogWidth: CGFloat = 270
        
        ios11viewYConstraint.constant = allowAlwaysButtonYOffset
        ios11viewWidthConstraint.constant = view.frame.width - (view.frame.width - alertDialogWidth)/2
            
        view.layoutIfNeeded()
    }
    
    override func startAnimations()
    {
        viewModel.requestLocationAuthorization()
        
        viewModel.locationAuthorizationChangedObservable
            .subscribe(onNext: finish)
            .disposed(by: disposeBag)
    }
    
    override func finish()
    {        
        onboardingPageViewController.goToNextPage(forceNext: true)
        disposeBag = DisposeBag()
    }
}
