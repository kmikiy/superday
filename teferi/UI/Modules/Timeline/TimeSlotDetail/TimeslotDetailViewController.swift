import UIKit
import RxSwift

enum SectionType: Int
{
    case singleSlot
    case categorySelection
    case time
    case map
    
    enum TimeRowType: Int
    {
        case start
        case end
    }
    
    enum CategorySelectionRowType: Int
    {
        case categoryDetail
        case categprySelection
    }
}

class TimeslotDetailViewController: UIViewController
{
    // MARK: Private Properties
    fileprivate var viewModel : TimeslotDetailViewModel!
    fileprivate var presenter : TimeslotDetailPresenter!
    fileprivate let disposeBag = DisposeBag()
    @IBOutlet private weak var blurView : UIVisualEffectView!
    @IBOutlet private weak var shadowView : ShadowView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    fileprivate var slotTimelineItem : SlotTimelineItem!
    {
        didSet
        {
            guard let tableView = self.tableView else { return }
            
            tableView.reloadSections([SectionType.singleSlot.rawValue, SectionType.time.rawValue, SectionType.map.rawValue], animationStyle: .fade)
            tableView.reloadRows(at: [IndexPath(row: SectionType.CategorySelectionRowType.categoryDetail.rawValue, section: SectionType.categorySelection.rawValue)], with: .fade)
        }
    }
    fileprivate var isShowingCategorySelection = false
    {
        didSet
        {
            guard let tableView = self.tableView else { return }
            tableView.reloadSections([SectionType.categorySelection.rawValue], animationStyle: .fade)
        }
    }
    
    // MARK: - Init
    func inject(presenter: TimeslotDetailPresenter, viewModel: TimeslotDetailViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        createBindings()
        
        containerView.backgroundColor = viewModel.isShowingSubSlot ? .white : .clear
        topConstraint.constant = viewModel.isShowingSubSlot ? 58 : 50
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorColor = UIColor(r: 242, g: 242, b: 242)
        tableView.allowsSelection = true
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: TimelineCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "SimpleDetailCell", bundle: Bundle.main), forCellReuseIdentifier: SimpleDetailCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "CategorySelectionCell", bundle: Bundle.main), forCellReuseIdentifier: CategorySelectionCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "MapCell", bundle: Bundle.main), forCellReuseIdentifier: MapCell.cellIdentifier)
        
        let headerView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.bounds.width, height: 8)))
        headerView.backgroundColor = .clear
        tableView.tableHeaderView = headerView
        
        let footerView = UIView()
        footerView.backgroundColor = .clear
        tableView.tableFooterView = footerView
        
        blurView.layer.cornerRadius = 10
        blurView.clipsToBounds = true
    }
    
    func createBindings()
    {
        viewModel.slotTimelineItemObservable
            .subscribe(onNext: { [unowned self] (item) in
                guard let item = item
                else
                {
                    if !self.viewModel.isShowingSubSlot
                    {
                        if let presentedViewController = self.presentedViewController
                        {
                            presentedViewController.dismiss(animated: true, completion: {
                                self.presenter.dismiss()
                            })
                        }
                        else
                        {
                            self.presenter.dismiss()
                        }
                    }
                    return

                }
                self.slotTimelineItem = item
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    @IBAction func closeButtonAction(_ sender: UIButton)
    {
        self.presenter.dismiss()
    }
}

extension TimeslotDetailViewController : UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let sectionType = SectionType(rawValue: indexPath.section) else { return }
        switch sectionType {
        case .categorySelection:
            
            guard let categorySelectionRowType = SectionType.CategorySelectionRowType.init(rawValue: indexPath.row) else { return }
            switch categorySelectionRowType {
            case .categoryDetail:
                isShowingCategorySelection = !isShowingCategorySelection
            default:
                break
            }
            
        case .time:
            
            guard let timeRowType = SectionType.TimeRowType.init(rawValue: indexPath.row) else { break }
            guard slotTimelineItem.timeSlots.count == 1, let timeSlot = slotTimelineItem.timeSlots.first else { break }
            switch timeRowType {
            case .start:
                guard let timeSlotBefore = viewModel.timeSlot(before: timeSlot) else { return }
                presenter.showEditBreakTime(firstTimeSlot: timeSlotBefore, secondTimeSlot: timeSlot, editingStartTime: true, updateStartDateSubject: viewModel.updateStartDateSubject)
            case .end:
                guard let timeSlotAfter = viewModel.timeSlot(after: timeSlot) else { return }
                presenter.showEditBreakTime(firstTimeSlot: timeSlot, secondTimeSlot: timeSlotAfter, editingStartTime: false, updateStartDateSubject: viewModel.updateStartDateSubject)
            }
            
        default:
            break
        }
    }
}

extension TimeslotDetailViewController : UITableViewDataSource
{
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let sectionType = SectionType(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .singleSlot:
            return 1
        case .categorySelection:
            return isShowingCategorySelection ? 2 : 1
        case .time:
            if slotTimelineItem.isRunning
            {
                return 1
            }
            else
            {
                return 2
            }
        case .map:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let sectionType = SectionType(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch sectionType {
        case .singleSlot:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TimelineCell.cellIdentifier, for: indexPath) as! TimelineCell
            cell.configure(slotTimelineItem: slotTimelineItem, useType: .editTimeslot)
            setup(cell)
            return cell
            
        case .categorySelection:
            
            guard let categorySelectionRowType = SectionType.CategorySelectionRowType.init(rawValue: indexPath.row) else { return UITableViewCell() }
            
            switch categorySelectionRowType {
            case .categoryDetail:
                let cell = tableView.dequeueReusableCell(withIdentifier: SimpleDetailCell.cellIdentifier, for: indexPath) as! SimpleDetailCell
                cell.show(title: L10n.editTimeSlotCategoryTitle, value: slotTimelineItem.category.description)
                setup(cell)
                if isShowingCategorySelection { removeSeparator(cell) }
                return cell
            case .categprySelection:
                let cell = tableView.dequeueReusableCell(withIdentifier: CategorySelectionCell.cellIdentifier, for: indexPath) as! CategorySelectionCell
                cell.configure(with: viewModel.categoryProvider, slotTimelineItem: slotTimelineItem)
                
                cell.editView
                    .editEndedObservable
                    .subscribe(onNext: viewModel.updateSlotTimelineItem)
                    .disposed(by: disposeBag)
                
                setup(cell)
                return cell
            }
            
        case .time:
            
            guard let timeRowType = SectionType.TimeRowType.init(rawValue: indexPath.row) else { return UITableViewCell() }

            let cell = tableView.dequeueReusableCell(withIdentifier: SimpleDetailCell.cellIdentifier, for: indexPath) as! SimpleDetailCell
            
            switch timeRowType {
            case .start:
                cell.show(title: L10n.editTimeSlotStartTitle, value: slotTimelineItem.startTimeText)
            case .end:
                cell.show(title: L10n.editTimeSlotEndTitle, value: slotTimelineItem.endTimeText)
            }
            
            setup(cell)
            return cell
            
        case .map:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: MapCell.cellIdentifier, for: indexPath) as! MapCell
            cell.configure(with: slotTimelineItem.timeSlots)
            setup(cell)
            removeSeparator(cell)
            return cell
        }
    }
    
    private func removeSeparator(_ cell: UITableViewCell)
    {
        cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0)
    }
    
    private func setup(_ cell: UITableViewCell)
    {
        cell.selectionStyle = .none
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
    }
}
