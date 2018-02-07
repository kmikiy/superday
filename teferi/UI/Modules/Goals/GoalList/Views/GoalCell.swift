import UIKit

class GoalCell: UITableViewCell
{
    static let cellIdentifier = "goalCell"
    
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var progressIndicator: UIProgressView!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var percentageLabel: UILabel!
    @IBOutlet private weak var bottomSpacing: NSLayoutConstraint!
    
    var isCurrentGoal = false
    {
        didSet
        {
            bottomSpacing.constant = isCurrentGoal ? 40 : 12
            dateLabel.isHidden = isCurrentGoal
        }
    }
    
    var goal: Goal!
    {
        didSet
        {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE MMMM d"
            dateLabel.text = dateFormatter.string(from: goal.date).uppercased()
            
            if goal.category == .unknown
            {
                categoryLabel.text = "No goal"
                categoryLabel.textColor = UIColor.lightGray
                
                progressIndicator.progress = 0
                durationLabel.text = nil
                percentageLabel.text = nil
            }
            else
            {
                let completion = goal.targetTime == 0 ? 0 : Float(goal.timeSoFar / goal.targetTime)
                
                categoryLabel.text = goal.category.description + (completion >= 1 ? "🏆" : "")
                categoryLabel.textColor = UIColor.almostBlack
                
                progressIndicator.tintColor = goal.category.color
                progressIndicator.layer.cornerRadius = 2
                progressIndicator.progress = completion
                
                durationLabel.text = formatedElapsedTimeText(for: goal.timeSoFar)
                
                percentageLabel.text = "\(Int(completion * 100))%"
            }
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        separatorInset = UIEdgeInsetsMake(0, 16, 0, 0)
    }
}
