import RxSwift
import RxCocoa

extension Reactive where Base: LoadingView
{
    var isActive: Binder<Bool> {
        return Binder(self.base) { view, active in
            if active {
                view.show()
            } else {
                view.hide()
            }
        }
    }
}

