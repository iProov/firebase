#
# Be sure to run `pod lib lint iProovFirebase.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'iProovFirebase'
  s.version          = '0.1.0'
  s.summary          = 'A short description of iProovFirebase.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Jonathan Ellis/iProovFirebase'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jonathan Ellis' => 'jonathan.ellis@iproov.com' }
  s.source           = { :git => 'https://github.com/Jonathan Ellis/iProovFirebase.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.source_files = 'iProovFirebase/Classes/**/*'
  
  # s.resource_bundles = {
  #   'iProovFirebase' => ['iProovFirebase/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.dependency 'iProov', '~> 11.0.0'
  s.dependency 'Firebase/Functions'
  s.dependency 'Firebase/Auth'
  
end
