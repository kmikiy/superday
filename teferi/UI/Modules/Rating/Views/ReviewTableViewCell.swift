import UIKit

class ReviewTableViewCell: UITableViewCell
{
    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var categoryBackgroundView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    private let hourAndMisnutesMask = "%02d:%02d"
    private let secondsMask = ":%02d"
    
    func setup(with activity: Activity, totalDuration: TimeInterval)
    {
        categoryImageView.image = activity.category.icon.image
        
        categoryBackgroundView.backgroundColor = activity.category.color
        categoryBackgroundView.layer.cornerRadius = categoryBackgroundView.bounds.width / 2
        
        categoryLabel.text = activity.category.description
        percentageLabel.text = "\(Int(activity.duration / totalDuration * 100))%"
        
        let seconds = Int(activity.duration) % 60
        let minutes = (Int(activity.duration) / 60) % 60
        let hours = Int(activity.duration / 3600)
        
        let attributedTimeString = NSMutableAttributedString()
        
        let hoursAndMinutesAttributedString = NSMutableAttributedString(string: String(format: hourAndMisnutesMask, hours, minutes))
        hoursAndMinutesAttributedString.addAttributes([NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14),
                                                       NSAttributedStringKey.foregroundColor : UIColor.init(r: 94, g: 91, b: 91)],
                                                      range: NSMakeRange(0, hoursAndMinutesAttributedString.length))
        attributedTimeString.append(hoursAndMinutesAttributedString)
        
        let secondsAttributedString = NSMutableAttributedString(string: String(format: secondsMask, seconds))
        secondsAttributedString.addAttributes([NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14),
                                               NSAttributedStringKey.foregroundColor : UIColor.init(r: 206, g: 205, b: 205)],
                                              range: NSMakeRange(0, secondsAttributedString.length))
        attributedTimeString.append(secondsAttributedString)
        
        timeLabel.attributedText = attributedTimeString
    }
}
