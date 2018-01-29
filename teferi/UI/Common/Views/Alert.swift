import UIKit
import SnapKit

class Alert: UIView
{
    private static var currentAlert: Alert? = nil
    
    private let viewController: UIViewController?
    private let containerView = UIView()
    private let effectBackground = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.extraLight))
    private let shadow: UIImageView = UIImageView(image: UIImage.resizableShadowImage(cornerRadius: 10, shadowBlur: 4))
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(inViewController viewController: UIViewController? = nil)
    {
        self.viewController = viewController
        
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        backgroundColor = UIColor.clear
        
        containerView.backgroundColor = UIColor.clear
        containerView.clipsToBounds = false
        
        effectBackground.layer.cornerRadius = 10
        effectBackground.clipsToBounds = true
        
        addSubview(containerView)
        containerView.addSubview(shadow)
        containerView.addSubview(effectBackground)
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }

        effectBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        shadow.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(-4)
        }
        
        let contentView = buildContentView()
        effectBackground.contentView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.isHidden = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(Alert.onPan(recognizer:)))
        self.addGestureRecognizer(pan)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(Alert.hide))
        swipe.direction = UISwipeGestureRecognizerDirection.down
    }
    
    internal func buildContentView() -> UIView
    {
        fatalError("Subclass must override")
    }
    
    @objc private func onPan(recognizer: UIPanGestureRecognizer)
    {
        guard let superview = superview else { return }
        
        let translation = recognizer.translation(in: superview)
        
        switch recognizer.state {
        case .changed:
            self.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
        case .cancelled, .ended:
            if translation.y > 20 {
                hide()
            } else {
                recognizer.setTranslation(CGPoint.zero, in: superview)

                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.4,
                    initialSpringVelocity: 0.7,
                    options: [],
                    animations: {
                        self.transform = CGAffineTransform.identity
                }, completion: nil)
            }
        default:
            break
        }
    }
    
    override func didMoveToSuperview()
    {
        super.didMoveToSuperview()
        guard let _ = superview, let viewController = viewController else { return }
        
        self.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(viewController.bottomLayoutGuide.snp.top)
        }
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        effectBackground.layer.shadowPath = UIBezierPath(rect: effectBackground.bounds).cgPath
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
    {
        if containerView.frame.contains(point) {
            let newPoint = containerView.convert(point, from: self)
            return containerView.hitTest(newPoint, with:event)
        }
        
        return nil
    }
    
    // MARK: Public Methods
    
    func show()
    {
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        
        guard Alert.currentAlert == nil else { return }
        Alert.currentAlert = self
        
        if viewController == nil {
            window.addSubview(self)
        } else {
            viewController?.view.addSubview(self)
        }
        
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height + 20)
        containerView.isHidden = false
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.3,
            initialSpringVelocity: 0.8,
            options: [],
            animations: { [unowned self] in
                self.containerView.transform = CGAffineTransform.identity
            },
            completion: nil)
    }
    
    func hide()
    {
        guard let _ = superview else { return }
        Alert.currentAlert = nil
        
        UIView.animate(
            withDuration: 0.3,
            animations: { [unowned self] in
                self.containerView.transform = CGAffineTransform(translationX: self.frame.origin.x, y: self.frame.origin.y + 100)
            },
            completion: { _ in
                self.containerView.transform = CGAffineTransform.identity
                self.removeFromSuperview()
        })
    }
    
    @objc static func hide()
    {
        guard let alert = Alert.currentAlert else { return }
        alert.hide()
    }
}
