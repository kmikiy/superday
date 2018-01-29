platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'teferi' do
  use_frameworks!

    pod 'RxSwift',    '~> 3.0.0'
    pod 'RxCocoa',    '~> 3.0.0'
    pod 'SwiftyBeaver'
    pod 'SnapKit', '~> 3.0'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'JTAppleCalendar', '6.0.2'
    pod 'SwiftGen', '4.1.0'
    pod 'SwiftLint', '0.16.1'
    pod 'RxDataSources', '~> 1.0'
    pod 'Firebase/Core'

  target 'teferiTests' do
    inherit! :search_paths
    pod 'Nimble', '~> 7.0.1'
    pod 'RxTest', '~> 3.0.0'
    pod 'Firebase'
  end

  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['SWIFT_VERSION'] = '3.2'
          end
      end
  end
end
