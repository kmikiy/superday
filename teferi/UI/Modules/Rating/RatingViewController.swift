import UIKit
import RxSwift

class RatingViewController: UIViewController
{
    @IBOutlet weak var chartView: DailySummaryPieChartActivity!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var starsView: StarsView!
    @IBOutlet weak var starViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var starViewYAlignmentConstraint: NSLayoutConstraint!
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var bottomContainerView: UIView!
    
    fileprivate var viewModel: RatingViewModel!
    private var presenter : RatingPresenter!
    private var disposeBag : DisposeBag = DisposeBag()
    
    fileprivate let cellIdentifier = "ratingCellIdentifier"
        
    func inject(viewModel: RatingViewModel,
                presenter : RatingPresenter)
    {
        self.viewModel = viewModel
        self.presenter = presenter
    }
    
    // MARK: - Liffecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.layer.cornerRadius = 10
        
        chartView.dailyActivities = viewModel.activities
        chartView.innerCircleDiameterPercentage = 0.55
        tableView.rowHeight = 44
        
        titleLabel.text = L10n.ratingTitle
        messageLabel.text = L10n.ratingMessage
        thankYouLabel.text = L10n.ratingThankYou
        
        starsView.selectionObservable
            .subscribe(onNext: finalizeRating)
            .disposed(by: disposeBag)
        
        viewModel.didShowRating()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        topContainerView.setCorner(radius: 10, corners: [.topRight, .topLeft])
        bottomContainerView.setCorner(radius: 10, corners: [.bottomRight, .bottomLeft])
    }
    
    @IBAction func closeAction(_ sender: UIButton)
    {
        presenter.dismiss()
    }
    
    private func finalizeRating(_ rating: Int)
    {
        viewModel.setRating(rating)
        
        starsView.isUserInteractionEnabled = false
        
        self.starViewHeightConstraint.constant = 0.65 * self.starViewHeightConstraint.constant
        self.starViewYAlignmentConstraint.constant = 14
        
        UIView.animate(withDuration: 0.4)
        {
            self.view.layoutIfNeeded()
            self.thankYouLabel.alpha = 1.0
        }
    }
}

extension RatingViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return viewModel.activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ReviewTableViewCell
        cell.setup(with: viewModel.activities[indexPath.row], totalDuration: viewModel.activities.totalDurations)
        
        return cell
    }
}
