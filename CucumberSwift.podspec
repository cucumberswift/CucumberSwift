Pod::Spec.new do |s|
    s.name             = 'CucumberSwift'
    s.version          = '5.0.5'
    s.summary          = 'A lightweight swift only cucumber implementation.'

    s.description      = <<-DESC
  This is a swift only cucumber implementation. This particular implementation contains feature, scenario and step level hooks that Cucumberish does not and has the added benefit of not requiring an objective-c bridging header 
                         DESC
  
    s.homepage         = 'https://github.com/Tyler-Keith-Thompson/CucumberSwift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Tyler Thompson' => 'Tyler.Thompson@Asynchrony.com' }
    s.source           = { :git => 'https://github.com/Tyler-Keith-Thompson/CucumberSwift.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '13.0'
    s.osx.deployment_target = '10.15'
    s.tvos.deployment_target = '13.0'
    s.swift_version = '5.4'
  
    s.source_files = 'Sources/**/*.{swift,h,m}'
    s.exclude_files = 'Sources/CucumberSwift/CucumberSwift.docc/'

    s.dependency "CucumberSwiftExpressions"

    s.framework = "XCTest"
    s.pod_target_xcconfig = {
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PLATFORM_DIR)/Developer/Library/Frameworks"',
    }
end
  
