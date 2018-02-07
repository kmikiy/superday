import UIKit
import RxSwift
import RxDataSources

class GoalViewController: UIViewController
{
    private let disposeBag = DisposeBag()
    private var viewModel : GoalViewModel!
    private var presenter : GoalPresenter!
    private var dataSource: RxTableViewSectionedAnimatedDataSource<GoalSection>!
    
    @IBOutlet private var tableView : UITableView!    
    private let header = GoalHeader.fromNib()
    
    func inject(presenter: GoalPresenter, viewModel: GoalViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
        
        dataSource = RxTableViewSectionedAnimatedDataSource<GoalSection>(
            animationConfiguration: AnimationConfiguration(
                insertAnimation: .fade,
                reloadAnimation: .fade,
                deleteAnimation: .fade
            ),
            configureCell: constructCell
        )
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 78
        tableView.register(UINib.init(nibName: "GoalCell", bundle: Bundle.main), forCellReuseIdentifier: GoalCell.cellIdentifier)
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)

        tableView.tableHeaderView = header
        header.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        
        let footerView = UIView(frame: .zero)
        footerView.backgroundColor = .clear
        tableView.tableFooterView = footerView
        
        tableView.addTopShadow()
        
        createBindings()
    }

    // MARK: Private Methods
    private func barButtonItem(forGoal goal: Goal?) -> UIBarButtonItem?
    {
        guard let goal = goal else { return nil }
        
        let buttonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.edit, target: nil, action: nil)
        buttonItem.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.presenter.showEditGoal(withGoal: goal)
            })
            .disposed(by: self.disposeBag)
        
        return buttonItem
    }
    
    private func createBindings()
    {
        viewModel.goalsObservable
            .map({ [GoalSection(items:$0)] })
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        viewModel.todaysGoal
            .map(barButtonItem)
            .subscribe(onNext: {
                self.navigationItem.rightBarButtonItem = $0
            })
            .disposed(by: disposeBag)
        
        viewModel.lastGoal
            .subscribe(onNext: { goal in
                self.header.configure(withViewModel: self.viewModel, andGoal: goal)
            })
            .disposed(by: disposeBag)
        
        header.newGoalButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.presenter.showNewGoalUI()
            })
            .disposed(by: self.disposeBag)
        
        viewModel.suggestionObservable
            .subscribe(onNext: { [unowned self] suggestion in
                guard let suggestion = suggestion else {
                    GoalSuggestionAlert.hide()
                    return                    
                }
                GoalSuggestionAlert(inViewController: self, text: suggestion).show()
            })
            .disposed(by: self.disposeBag)
    }

    private func constructCell(dataSource: TableViewSectionedDataSource<GoalSection>,
                               tableView: UITableView,
                               indexPath: IndexPath,
                               item:Goal) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: GoalCell.cellIdentifier, for: indexPath) as! GoalCell
        cell.isCurrentGoal = viewModel.isCurrentGoal(item)
        cell.goal = item
        cell.selectionStyle = .none
        return cell
    }
}
