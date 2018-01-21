Pod::Spec.new do |s|
  s.name         = 'RTCoreDataStack'
  s.version      = '4.1.1'
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
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  s.swift_version = '4.0'

  s.description  = <<-DESC
                   RT(Swift)CoreDataStack is pure Swift wrapper for Core Data stack. It works equally well in simple apps with just the main (view) context as well as is data intensive apps which require continuous import and display of data of any complexity.

				   * Has two PersistentStoreCoordinator instances: `mainCoordinator` and `writerCoordinator`
                   * Use `mainContext` or `viewContext` for all your UI needs (connected to main PSC).
                   * Use as many `importerContext`s as you need - all import is done automatically on background thread. Connected to writerPSC.
				   * Automatic merge between `importerContext` and the `mainContext`
                   * Also includes `editorContext`
                   * All MOCs are already predefined to use appropriate `mergePolicy` values.
                   * Easy-to-use ability to create any specific MOC instance you may need.

                   * Includes `ManagedObjectType` protocol which you can adopt and automatically get simple to use properly-typed methods for `NSFetchRequest` of objects, specific properties, count + automatic generation of typed `NSFetchedResultsController`
                   * Custom non-throwable `MOC.save` method which automatically performs save of the `parentContext` too if there is one and returns save error inside optional callback.
                   DESC
end
