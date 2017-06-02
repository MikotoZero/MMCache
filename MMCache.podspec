Pod::Spec.new do |s|
  s.name         = "MMCache"
  s.version      = "0.1.2"
  s.summary      = "App cache manager for swift 3"
  s.description  = <<-DESC
                            This is MMCache. An app cache manager for swift 3
                   DESC
  s.homepage     = "https://github.com/MikotoZero/MMCache"
  s.license         = { :type => "MIT", :file => "LICENSE" }
  s.author          = { "MikotoZero" => "ding3725371@hotmail.com" }
  s.ios.deployment_target = '8.0'

  s.source       = { :git => "https://github.com/MikotoZero/MMCache.git", :tag => s.version.to_s }
  s.source_files  = "Source/**/*.{swift}"
  s.resource = "Source/DataBase/*.xcdatamodeld"
  s.frameworks = 'CoreData'

  s.requires_arc = true
  s.pod_target_xcconfig     =  {
      'SWIFT_VERSION' => '3.0',
  }

end
