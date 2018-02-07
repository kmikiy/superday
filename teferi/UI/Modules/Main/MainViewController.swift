import UIKit
import RxSwift
import MessageUI
import CoreMotion
import CoreGraphics
import QuartzCore
import SnapKit

class MainViewController : UIViewController, MFMailComposeViewControllerDelegate
{
    // MARK: Private Properties
    private var viewModel : MainViewModel!
    private var presenter : MainPresenter!

    private var pagerViewController : PagerViewController!
    
    private let disposeBag = DisposeBag()
    
    private var editView : EditTimeSlotView!
    private var addButton : AddTimeSlotView!
    private var calendarButton : UIButton!
    
    @IBOutlet private weak var welcomeMessageView: WelcomeView!
    
    func inject(presenter:MainPresenter, viewModel: MainViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    // MARK: UIViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        pagerViewController = presenter.setupPagerViewController(vc: self.childViewControllers.firstOfType())
        
        //Edit View
        editView = EditTimeSlotView(categoryProvider: viewModel.categoryProvider)
        view.addSubview(editView)
        editView.constrainEdges(to: view)
        
        //Add button
        addButton = (Bundle.main.loadNibNamed("AddTimeSlotView", owner: self, options: nil)?.first) as? AddTimeSlotView
        addButton.categoryProvider = viewModel.categoryProvider
        view.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
        calendarButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        calendarButton.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        calendarButton.setBackgroundImage(Image(asset: Asset.icCalendar), for: .normal)
        calendarButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.presenter.toggleCalendar()
            })
            .disposed(by: disposeBag)
        
        setupNavigationBar()
        
        createBindings()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        viewModel.active = true
        
        if viewModel.shouldShowCMAccessForExistingUsers
        {
            presenter.showCMAccessForExistingUsers()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        viewModel.active = false
    }
    
    // MARK: Private Methods
    
    private func createBindings()
    {
        editView.dismissAction = { [unowned self] in self.viewModel.notifyEditingEnded() }
        
        //Edit state
        viewModel
            .isEditingObservable
            .subscribe(onNext: onEditChanged)
            .disposed(by: disposeBag)
        
        viewModel
            .beganEditingObservable
            .subscribe(onNext: editView.onEditBegan)
            .disposed(by: disposeBag)
        
        //Category creation
        addButton
            .categoryObservable
            .subscribe(onNext: viewModel.addNewSlot)
            .disposed(by: disposeBag)
        
        editView
            .editEndedObservable
            .subscribe(onNext: viewModel.updateSlotTimelineItem)
            .disposed(by: disposeBag)
        
        viewModel
            .dateObservable
            .subscribe(onNext: onDateChanged)
            .disposed(by: disposeBag)
        
        viewModel.showPermissionControllerObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: presenter.showPermissionController)
            .disposed(by: disposeBag)
        
        viewModel.welcomeMessageHiddenObservable
            .bind(to: welcomeMessageView.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.moveToForegroundObservable
            .subscribe(onNext: onBecomeActive)
            .disposed(by: disposeBag)
        
        viewModel.locating
            .bind(to: LoadingView.locating.rx.isActive)
            .disposed(by: disposeBag)
        
        viewModel.generating
            .bind(to: LoadingView.generating.rx.isActive)
            .disposed(by: disposeBag)
        
        viewModel.calendarDay
            .bind(to: calendarButton.rx.title(for: .normal))
            .disposed(by: disposeBag)
        
        viewModel.showAddGoalAlert
            .subscribe(onNext: { [unowned self] show in
                if show {
                    AddGoalAlert(inViewController: self, tapClosure: self.addGoalAlertTap).show()
                } else {
                    AddGoalAlert.hide()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func addGoalAlertTap()
    {
        viewModel.markAddGoalAlertShown()
        presenter.showNewGoalUI()
    }
    
    private func onBecomeActive()
    {
        if viewModel.shouldShowWeeklyRatingUI
        {
            presenter.showWeeklyRating(fromDate: viewModel.weeklyRatingStartDate, toDate: viewModel.weeklyRatingEndDate)
        }
    }
    
    private func onDateChanged(date: Date)
    {
        let today = viewModel.currentDate
        let isToday = today.ignoreTimeComponents() == date.ignoreTimeComponents()
        let alpha = CGFloat(isToday ? 1 : 0)
        
        UIView.animate(withDuration: 0.3)
        {
            self.addButton.alpha = alpha
        }
        
        addButton.close()
        addButton.isUserInteractionEnabled = isToday
    }
    
    private func onEditChanged(_ isEditing: Bool)
    {
        //Close add menu
        addButton.close()
        
        //Grey out views
        editView.isEditing = isEditing
    }

    private func setupNavigationBar()
    {
        let buttonItems = [
            .createFixedSpace(of: 8),
            UIBarButtonItem(customView: calendarButton)
        ]
        
        var rightItems = navigationItem.rightBarButtonItems ?? []
        rightItems.insert(contentsOf: buttonItems, at: 0)
        
        navigationItem.rightBarButtonItems = rightItems
    }
}
