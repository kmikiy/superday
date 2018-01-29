import UIKit
import RxSwift
import RxCocoa

class NewGoalViewController: UIViewController
{
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topDescriptionLabel: UILabel!
    @IBOutlet fileprivate weak var timeDescriptionLabel: UILabel!
    @IBOutlet private weak var middleDescriptionLabel: UILabel!
    @IBOutlet private weak var newGoalButton: UIButton!
    @IBOutlet weak var timesCollectionView: CustomCollectionView!
    @IBOutlet weak var categoriesCollectionView: CustomCollectionView!
    
    fileprivate var viewModel: NewGoalViewModel!
    private var presenter: NewGoalPresenter!
    private let disposeBag = DisposeBag()
    
    func inject(presenter: NewGoalPresenter, viewModel: NewGoalViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        titleLabel.text = L10n.newGoalTitle
        topDescriptionLabel.text = L10n.newGoalTopDescription
        middleDescriptionLabel.text = L10n.newGoalMiddleDescription
        newGoalButton.setTitle(viewModel.buttonTitle, for: .normal)

        let timeGradientOverlay = PickerGradientOverlay()
        view.addSubview(timeGradientOverlay)
        timeGradientOverlay.snp.makeConstraints { (make) in
            make.edges.equalTo(timesCollectionView.snp.edges)
        }
        
        let categoryGradientOverlay = PickerGradientOverlay(middleGap: 10)
        view.addSubview(categoryGradientOverlay)
        categoryGradientOverlay.snp.makeConstraints { (make) in
            make.edges.equalTo(categoriesCollectionView.snp.edges)
        }
        
        categoriesCollectionView.loops = true
        
        timesCollectionView.customDelegate = self
        categoriesCollectionView.customDelegate = self
        
        timesCollectionView.customDatasource = CustomCollectionViewArrayDatasource<GoalTimeCell, GoalTime>(
            items: viewModel.goalTimes,
            cellIdentifier: "goalTimeCell",
            initialValue: viewModel.initialTime,
            configureCell: { _, goalTime, cell in
                cell.goalTime = goalTime
                return cell
            })
        
        categoriesCollectionView.customDatasource = CustomCollectionViewArrayDatasource<GoalCategoryCell, Category>(
            items: viewModel.categories,
            cellIdentifier: "goalCategoryCell",
            initialValue: viewModel.initialCategory,
            configureCell: { _, category, cell in
                cell.category = category
                return cell
            })

        createBindings()
    }

    private func createBindings()
    {
        closeButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.presenter.dismiss()
            })
            .disposed(by: disposeBag)
        
        newGoalButton.rx.tap
            .subscribe(onNext: saveGoal)
            .disposed(by: disposeBag)
    }
    
    private func saveGoal()
    {
        self.viewModel.saveGoal(completion: {
            self.presenter.dismiss(showEnableNotifications: $0)
        })
    }
}

extension NewGoalViewController: CustomCollectionViewDelegate
{
    func itemSelected(for collectionView: UICollectionView, at row: Int)
    {
        if collectionView == timesCollectionView {
            let goalTime = viewModel.goalTimes[row]
            timeDescriptionLabel.text = goalTime.unitString
            viewModel.durationSelectedVariable.value = goalTime.goalTime
            return
        }
        
        let category = viewModel.categories[row]
        viewModel.categorySelectedVariable.value = category
    }
}
