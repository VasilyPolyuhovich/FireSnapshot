source 'https://cdn.cocoapods.org/'

target 'FireSnapshot' do
  use_frameworks!
  pod 'Firebase/Firestore'
  pod 'FirebaseFirestoreSwift'
  pod 'Firebase/Storage'

  target 'FireSnapshotTests' do
    pod 'Firebase/Core'
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(FRAMEWORK_SEARCH_PATHS)']
  end
end
