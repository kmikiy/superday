import UIKit
import RxCocoa
import RxSwift

class WeeklySummaryViewController: UIViewController
{
    fileprivate var viewModel : WeeklySummaryViewModel!
    private var presenter : WeeklySummaryPresenter!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var weeklyChartView: ChartView!
    
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var categoryButtons: ButtonsCollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pieChart: ActivityPieChartView!
    @IBOutlet weak var emptyStateView: WeeklySummaryEmptyStateView!
    @IBOutlet weak var monthSelectorView: UIView!
    
    private var disposeBag = DisposeBag()
    
    func inject(presenter:WeeklySummaryPresenter, viewModel: WeeklySummaryViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = Color.white
        self.scrollView.addSubview(self.emptyStateView)
        
        previousButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.viewModel.nextWeek()
            })
            .disposed(by: disposeBag)
        
        nextButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.viewModel.previousWeek()
            })
            .disposed(by: disposeBag)
        
        viewModel.weekTitle
            .bind(to: weekLabel.rx.text)
            .disposed(by: disposeBag)
        
        // Chart View
        weeklyChartView.datasource = viewModel
        weeklyChartView.delegate = self

        viewModel.firstDayIndex
            .subscribe(onNext:weeklyChartView.setWeekStart)
            .disposed(by: disposeBag)
        
        // Category Buttons
        categoryButtons.toggleCategoryObservable
            .subscribe(onNext:viewModel.toggleCategory)
            .disposed(by: disposeBag)
        
        categoryButtons.categories = viewModel.topCategories
            .do(onNext: { [unowned self] _ in
                self.weeklyChartView.refresh()
            })
        
        //Pie chart
        viewModel
            .weekActivities
            .map { activityWithPercentage in
                return activityWithPercentage.map { $0.0 }
            }
            .subscribe(onNext:self.pieChart.setActivities)
            .disposed(by: disposeBag)
        
        //Table view
        tableView.rowHeight = 48
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        viewModel.weekActivities
            .do(onNext: { [unowned self] activities in
                self.tableViewHeightConstraint.constant = CGFloat(activities.count * 48)
                self.view.setNeedsLayout()
            })
            .map { [unowned self] activities in
                return activities.sorted(by: self.areInIncreasingOrder)
            }
            .bind(to: tableView.rx.items(cellIdentifier: WeeklySummaryCategoryTableViewCell.identifier, cellType: WeeklySummaryCategoryTableViewCell.self)) {
                _, model, cell in
                cell.activityWithPercentage = model
            }
            .disposed(by: disposeBag)
        
        //Empty state
        viewModel.weekActivities
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { activityWithPercentage in
                self.emptyStateView.isHidden = !activityWithPercentage.isEmpty
            })
            .disposed(by: disposeBag)
        
        scrollView.addTopShadow()

    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        scrollView.flashScrollIndicators()
    }
    
    private func areInIncreasingOrder(a1: ActivityWithPercentage, a2: ActivityWithPercentage) -> Bool
    {
        return a1.1 > a2.1
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        self.emptyStateView.frame = self.weeklyChartView.frame
    }
}


extension WeeklySummaryViewController: ChartViewDelegate
{
    func pageChange(index: Int)
    {
        viewModel.setFirstDay(index: index)
    }
}
