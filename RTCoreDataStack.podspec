Pod::Spec.new do |s|
  s.name         = 'RTCoreDataStack'
  s.version      = '2.0.2'
  s.summary      = 'A Core Data library with lots of options to initialize the whole stack. Especially useful and usable for heavy background processing, since - by default - it uses setup with two PSCs, one for reading in the main thread and one for writing in background thread.'
  s.homepage     = 'https://github.com/radianttap/RTSwiftCoreDataStack'
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { 'Aleksandar Vacić' => 'radianttap.com' }
  s.social_media_url   			= "https://twitter.com/radiantav"
  s.ios.deployment_target 		= "8.4"
  s.watchos.deployment_target 	= "2.0"
  s.tvos.deployment_target 		= "9.0"
  s.source       = { :git => "https://github.com/radianttap/RTSwiftCoreDataStack.git" }
  s.source_files = 'RTCoreDataStack/*.{swift}'
  s.frameworks   = 'Foundation', 'CoreData'
end
