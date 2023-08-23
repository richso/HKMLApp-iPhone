# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'HKMLApp' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for HKMLApp
  #pod 'FacebookCore'
  #pod 'FacebookLogin'
  #pod 'FacebookShare'
  pod 'SKPhotoBrowser'
  
  pod 'SDWebImage'
  #, '~> 5.11'

  target 'HKMLAppTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'HKMLAppUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
               end
          end
   end
end
