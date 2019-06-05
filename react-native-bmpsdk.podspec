require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']
  s.authors      = { "850176300" => "deardarli.com" }
  s.homepage     = package['repository']['url']
  s.license      = package['license']
  s.platform     = :ios, "8.0"

  s.source       = { :git => package['repository']['url'], :tag => "v" + package['version'] }
  s.source_files = 'lib/ios/**/*.{h,m}'
  s.resource = ['lib/ios/Resources/Assets.xcassets']

  s.dependency 'React'
  s.dependency 'BaiduMapKit', "~> 3.4.0"
  s.dependency 'BMKLocationKit'
  s.static_framework = true
end
