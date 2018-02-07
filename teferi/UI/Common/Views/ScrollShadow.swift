import UIKit
import RxSwift
import RxCocoa
import SnapKit

extension UIScrollView
{
    func addTopShadow()
    {
        guard let superview = superview else { return }
      
        let headerShadow = ScrollShadow(contentOffset: self.rx.contentOffset.asObservable())
        superview.insertSubview(headerShadow, aboveSubview: self)
        
        headerShadow.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.leading)
            make.trailing.equalTo(self.snp.trailing)
            make.bottom.equalTo(self.snp.top)
            make.height.equalTo(40)
        }
    }
}

class ScrollShadow: UIView
{
    let disposeBag = DisposeBag()
    
    init(contentOffset: Observable<CGPoint>)
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        backgroundColor = UIColor.white
        
        layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.0
        layer.shadowRadius = 4.0
        
        contentOffset
            .map {
                Float($0.y) > 50 ? 1.0 : Float($0.y)/50
            }
            .subscribe(onNext: { [unowned self] opacity in
                self.layer.removeAllAnimations()
                let anim = CABasicAnimation(keyPath: "shadowOpacity")
                anim.fromValue = self.layer.shadowOpacity
                anim.toValue = opacity
                anim.duration = 0.3
                self.layer.add(anim, forKey: "shadowOpacity")
                
                self.layer.shadowOpacity = opacity
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }
}
