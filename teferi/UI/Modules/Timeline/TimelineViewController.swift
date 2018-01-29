import RxSwift
import RxCocoa
import UIKit
import CoreGraphics
import RxDataSources

protocol TimelineDelegate: class
{
    func didScroll(oldOffset: CGFloat, newOffset: CGFloat)
}

class TimelineViewController : UIViewController
{
    // MARK: Public Properties
    var date : Date { return self.viewModel.date }

    // MARK: Private Properties
    private let disposeBag = DisposeBag()
    fileprivate let viewModel : TimelineViewModel
    fileprivate let presenter : TimelinePresenter
    
    private var tableView : UITableView!
    
    private var willDisplayNewCell:Bool = false
    
    private var emptyStateView: EmptyStateView!
    private var voteView: TimelineVoteView!
    
    weak var delegate: TimelineDelegate?
    {
        didSet
        {
            let topInset = tableView.contentInset.top
            let offset = tableView.contentOffset.y
            delegate?.didScroll(oldOffset: offset + topInset, newOffset: offset + topInset)
        }
    }
    
    private var dataSource: RxTableViewSectionedAnimatedDataSource<TimelineSection>!

    // MARK: Initializers
    init(presenter: TimelinePresenter, viewModel: TimelineViewModel)
    {
        self.presenter = presenter
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
        dataSource = RxTableViewSectionedAnimatedDataSource<TimelineSection>(
            animationConfiguration: AnimationConfiguration(
                insertAnimation: .fade,
                reloadAnimation: .fade,
                deleteAnimation: .fade
            ),
            configureCell: constructCell
        )
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("NSCoder init is not supported for this ViewController")
    }
    
    // MARK: UIViewController lifecycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateView = EmptyStateView.fromNib()
        view.addSubview(emptyStateView!)
        emptyStateView!.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
        emptyStateView?.isHidden = true

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UINib.init(nibName: "TimelineCell", bundle: Bundle.main), forCellReuseIdentifier: TimelineCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "ExpandedTimelineCell", bundle: Bundle.main), forCellReuseIdentifier: ExpandedTimelineCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "CollapseCell", bundle: Bundle.main), forCellReuseIdentifier: CollapseCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "CategoryCell", bundle: Bundle.main), forCellReuseIdentifier: CategoryCell.cellIdentifier)
        tableView.register(UINib.init(nibName: "ShortTimelineCell", bundle: Bundle.main), forCellReuseIdentifier: ShortTimelineCell.cellIdentifier)
        
        setTableViewContentInsets()
        
        createBindings()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        if viewModel.canShowVotingUI()
        {
            showVottingUI()
        }
        
        setTableViewContentInsets()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if !viewModel.canShowVotingUI()
        {
            tableView.tableFooterView = nil
        }
    }

    // MARK: Private Methods
    private func setTableViewContentInsets()
    {
        // Magic numbers and direct access to tabBar due to the many layers in the UI: VC-> Container-> Pager-> Timeline.
        // This should be fixed by using: VC -> CollectionView -> TableView
        // This way we can just use automaticallyAdjustsScrollViewInsets
        tableView.contentInset = UIEdgeInsets(
            top: 34,
            left: 0,
            bottom: 49 + (tabBarController?.tabBar.frame.height ?? 0),
            right: 0)
    }
    
    private func createBindings()
    {
        viewModel.timelineItemsObservable
            .map({ [TimelineSection(items:$0)] })
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(disposeBag)
        
        viewModel.timelineItemsObservable
            .map{$0.count > 0}
            .bindTo(emptyStateView.rx.isHidden)
            .addDisposableTo(disposeBag)
        
        tableView.rx
            .modelSelected(TimelineItem.self)
            .subscribe(onNext: handleTableViewSelection )
            .addDisposableTo(disposeBag)
        
        tableView.rx.willDisplayCell
            .subscribe(onNext: { [unowned self] (cell, indexPath) in
                guard self.willDisplayNewCell && indexPath.row == self.tableView.numberOfRows(inSection: 0) - 1 else { return }
                
                (cell as! TimelineCell).animateIntro()
                self.willDisplayNewCell = false
            })
            .addDisposableTo(disposeBag)
        
        let oldOffset = tableView.rx.contentOffset.map({ $0.y })
        let newOffset = tableView.rx.contentOffset.skip(1).map({ $0.y })
        
        Observable<(CGFloat, CGFloat)>.zip(oldOffset, newOffset)
            { [unowned self] old, new -> (CGFloat, CGFloat) in
                // This closure prevents the header to change height when the scroll is bouncing
                
                let maxScroll = self.tableView.contentSize.height - self.tableView.frame.height + self.tableView.contentInset.bottom
                let minScroll = -self.tableView.contentInset.top
                
                if new < minScroll || old < minScroll { return (old, old) }
                if new > maxScroll || old > maxScroll { return (old, old) }
                
                return (old, new)
            }
            .subscribe(onNext: { [unowned self] (old, new) in
                let topInset = self.tableView.contentInset.top
                self.delegate?.didScroll(oldOffset: old + topInset, newOffset: new + topInset)
            })
            .addDisposableTo(disposeBag)
        
        viewModel.didBecomeActiveObservable
            .subscribe(onNext: { [unowned self] in
                if self.viewModel.canShowVotingUI()
                {
                    self.showVottingUI()
                }
            })
            .addDisposableTo(disposeBag)
        
        viewModel.dailyVotingNotificationObservable
            .subscribe(onNext: onNotificationOpen)
            .addDisposableTo(disposeBag)
    }
    
    private func handleTableViewSelection(timelineItem: TimelineItem)
    {
        switch timelineItem {
        case .slot(let item),
             .commuteSlot(let item):
            
            if item.timeSlots.count > 1
            {
                viewModel.expandSlots(item: item)
            }
            else
            {
                presenter.showEditTimeSlot(with: item.startTime)
            }
            
        case .expandedSlot(let item, _):
            
            presenter.showEditTimeSlot(with: item.startTime)
            
        case .collapseButton(_),
             .expandedCommuteTitle(_),
             .expandedTitle(_):
            
            break
            
        }
    }
    
    private func showVottingUI()
    {
        tableView.tableFooterView = nil
        
        voteView = TimelineVoteView.fromNib()
        
        tableView.tableFooterView = voteView
        
        voteView.setVoteObservable
            .subscribe(onNext: viewModel.setVote)
            .addDisposableTo(disposeBag)
    }
    
    private func onNotificationOpen(on date: Date)
    {
        guard
            date.ignoreTimeComponents() == viewModel.date.ignoreTimeComponents(),
            viewModel.canShowVotingUI()
        else { return }
        
        if tableView.tableFooterView == nil
        {
            showVottingUI()
        }
        
        tableView.reloadData()
        let bottomOffset = CGPoint(x: 0, y: tableView.contentSize.height + tableView.tableFooterView!.bounds.height - tableView.bounds.size.height)
        tableView.setContentOffset(bottomOffset, animated: true)
    }

    private func handleNewItem(_ items: [SlotTimelineItem])
    {
        let numberOfItems = tableView.numberOfRows(inSection: 0)
        guard numberOfItems > 0, items.count == numberOfItems + 1 else { return }
        
        willDisplayNewCell = true
        let scrollIndexPath = IndexPath(row: numberOfItems - 1, section: 0)
        tableView.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)
    }
    
    private func constructCell(dataSource: TableViewSectionedDataSource<TimelineSection>, tableView: UITableView, indexPath: IndexPath, timelineItem: TimelineItem) -> UITableViewCell
    {
        switch timelineItem {
        case .slot(let item):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: TimelineCell.cellIdentifier, for: indexPath) as! TimelineCell
            cell.configure(slotTimelineItem: item)
            cell.selectionStyle = .none
            
            cell.editClickObservable
                .map{ [unowned self] item in
                    let position = cell.categoryCircle.convert(cell.categoryCircle.center, to: self.view)
                    return (position, item)
                }
                .subscribe(onNext: self.viewModel.notifyEditingBegan)
                .addDisposableTo(cell.disposeBag)
            
            return cell
            
        case .commuteSlot(let item):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ShortTimelineCell.cellIdentifier, for: indexPath) as! ShortTimelineCell
            cell.configure(slotTimelineItem: item)
            cell.selectionStyle = .none
            return cell
            
        case .expandedCommuteTitle(let item):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ShortTimelineCell.cellIdentifier, for: indexPath) as! ShortTimelineCell
            cell.configure(slotTimelineItem: item, showStartAndDuration: false)
            cell.selectionStyle = .none
            return cell
        
        case .expandedTitle(let item):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.cellIdentifier, for: indexPath) as! CategoryCell
            cell.configure(slotTimelineItem: item)
            cell.selectionStyle = .none
            
            cell.editClickObservable
                .map{ [unowned self] item in
                    let position = cell.categoryCircle.convert(cell.categoryCircle.center, to: self.view)
                    return (position, item)
                }
                .subscribe(onNext: self.viewModel.notifyEditingBegan)
                .addDisposableTo(cell.disposeBag)
            
            return cell
            
        case .expandedSlot(let item, let hasSeparator):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: ExpandedTimelineCell.cellIdentifier, for: indexPath) as! ExpandedTimelineCell
            cell.configure(item: item, visibleSeparator: hasSeparator)
            cell.selectionStyle = .none
            return cell
            
        case .collapseButton(let color):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CollapseCell.cellIdentifier, for: indexPath) as! CollapseCell
            cell.configure(color: color)
            cell.selectionStyle = .none
            
            cell.collapseObservable
                .subscribe(onNext: viewModel.collapseSlots )
                .addDisposableTo(cell.disposeBag)
            
            return cell
            
        }
    }
    
    private func buttonPosition(forCellIndex index: Int) -> CGPoint
    {
        guard let cell = tableView.cellForRow(at: IndexPath(item: index, section: 0)) as? TimelineCell else {
            return CGPoint.zero
        }
        
        return cell.categoryCircle.convert(cell.categoryCircle.center, to: view)
    }
}
