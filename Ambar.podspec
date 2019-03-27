Pod::Spec.new do |s|
  s.name         = 'Ambar'
  s.version      = '6.1'
  s.summary      = 'Core Data library with lots of options to initialize the whole stack. Especially useful and usable for heavy background processing, since - by default - it uses setup with two PSCs, one for reading in the main thread and one for writing in background thread.'
  s.homepage     = 'https://github.com/radianttap/Ambar'
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { 'Aleksandar Vacić' => 'aplus.rs' }
  s.social_media_url   			= "https://twitter.com/radiantav"
  s.ios.deployment_target 		= "8.4"
  s.watchos.deployment_target 	= "3.0"
  s.tvos.deployment_target 		= "10.0"
  s.source       = { :git => "https://github.com/radianttap/Ambar.git" }
  s.source_files = 'Ambar/*.{swift}'
  s.frameworks   = 'Foundation', 'CoreData'

  s.swift_versions = ['4.2', '5.0']

  s.description  = <<-DESC
                   Ambar is pure Swift wrapper for Core Data stack. It works equally well in simple apps with just the main (view) context as well as is data intensive apps which require continuous import and display of data of any complexity.

				   * Has two PersistentStoreCoordinator instances: `mainCoordinator` and `writerCoordinator`
                   * Use `mainContext` or `viewContext` for all your UI needs (connected to main PSC).
                   * Use as many `importerContext`s as you need - all import is done automatically on background thread. Connected to writerPSC.
				   * Automatic merge between any `importerContext` and the `mainContext`
                   * Also includes `editorContext` (child of mainContext) for document-based apps.
                   * All MOCs are already predefined to use appropriate `mergePolicy` values.
                   * Easy-to-use ability to create any specific MOC instance you may need.
				   * Seamless migration of the existing Core Data store to another URL

                   * Includes `ManagedObjectType` protocol which you can adopt and automatically get simple to use properly-typed methods for `NSFetchRequest` of objects, specific properties, count + automatic generation of typed `NSFetchedResultsController`
                   * Custom non-throwable `MOC.save` method which automatically performs save of the `parentContext` too if there is one and returns save error inside optional callback.
                   DESC
end
