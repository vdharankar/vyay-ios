# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'vyay' do

# Pods for vyay

source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'

use_frameworks!

    pod 'SideMenu'
    # Add the Firebase pod for Google Analytics
    pod 'FirebaseAnalytics'
    pod 'Instructions', '~> 2.3.0'
    
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
end
