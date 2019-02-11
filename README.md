# Ambar
// formerly: RT(Swift)CoreDataStack //

> Noun
> ambar (plural ambars)
>
> Any of various kinds of subterranean or barn-like granary, depending on context, in Iran, Turkey, Russia or the Balkans.

Core Data stack I use for my Core Data based apps. It acts as replacement for `NSPersistantContainer` Apple added in iOS 10 SDK. It supports iOS 8.4, watchOS 3, tvOS 10 and above.

The library is fairly small and well commented. Latest version uses Swift 4.2. Supports SQLite and in-memory store types.

## Installation

### Manually 

Just drag `Ambar` folder into your project.

If you prefer to use dependency managers, see below. 
Releases are tagged with [Semantic Versioning](https://semver.org) in mind.

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Coordinator into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'Ambar', 	:git => 'https://github.com/radianttap/Ambar.git'
```

### Setting up with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Ambar into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "radianttap/Ambar"
```

## How to implement 

Create your instance of the stack in

* main thread
* as early as possible in your app, usually in `application(willFinishLaunching…)` in the AppDelegate.swift

You are free to create as many instances you want but I **really** recommend to create just one and pass it along to all the objects and view controllers. 

```swift
init(withDataModelNamed dataModel: String? = nil,
	     storeURL: URL? = nil,
	     callback: Callback? = nil)
```

You can supply the name (no extension) of the specific model you want to use. If you don’t, library will create a model by merging all models it finds in the app bundle.

You can supply a specific directory URL where the .sqlite file will be created. This is useful if you are using AppGroups (to share the store with extensions). If you don’t supply it, app will create the store in the app’s Documents directory.

Lastly, you *should* supply a simple callback to be informed when the store and the entire stack is ready to be used. Store setup is done asynchronously, which is why you have `isReady` property to let you know when you can use it.

## Main Features

Upon successful instantiation, the stack will have two instances of `NSPersistentStoreCoordinator`: 

```swift
private(set) var mainCoordinator: NSPersistentStoreCoordinator!

private(set) var writerCoordinator: NSPersistentStoreCoordinator!
```

You can access them if you need to but that shouldn’t really be necessary – see _Useful MOCs_ below. You can’t override nor delete them.

The first – main – should be used by main-thread bound contexts.  Mostly for reading data out of the store.

The second – writer – should be used by contexts created in background threads, usually for saving data into the store.

### Main MOC

```
private(set) var mainContext: NSManagedObjectContext!
```

An instance of `NSManagedObjectContext` created in the main thread, wired to `mainCoordinator` and with merge policy set to favor state of objects in the persistent store (on the disk) versus those in the memory.

You should use this MOC to drive your UI.

### Useful MOCs

Library has three additional useful methods, to create specific MOCs.

```
func importerContext() -> NSManagedObjectContext
```

This method returns MOC attached to mentioned `writerCoordinator` and its merge policy *favors state of objects in the memory*. This makes it perfect for background imports, since whatever is created / changed it would trample objects on the disk.

Call this method from background queues and use it to process items and save them directly to disk, without ever touching main thread. Since such processing is fairly short, it's very easy to import just about anything and still keep your UI thread fluent.

```
func temporaryContext() -> NSManagedObjectContext
```

This methods returns MOC wired to the `mainCoordinator` but with rollback merge policy. This means that you can do whatever you want in that MOC, objects in it will *never be stored* to disk.

I use this when I need a temporary copy of MOs for UI purposes. A poor man's value type for `NSManagedObject` instances.

```
func editorContext() -> NSManagedObjectContext
```

This method returns MOC created as child context of the `mainContext` but this time with merge policy that will *override whatever you have in the main MOC* and further along, all the way to the disk.

Textbook usage for this is when you need to create new objects, like new order in shopping app. Since those objects are created in new child MOC, you can freely do whatever in it without influencing objects in main context. If you delete this context, everything goes away, no harm done. If you save this context, everything is automatically propagated to main context first then also further to the disk.

## Killer feature: automatic, smart merge on save

If you have read carefully, you may have noticed that `importerContext` is connected to `writerCoordinator`. This means that objects created in it and later saved to the persistent store will never reach the `mainContext` and thus your UI will have no idea about them.

If you already have some objects loaded in `mainContext` and shown in the UI and those objects are updated through the background import and saved to disk, your main MOC will have no idea about those changes. Your `NSFetchedResultsControllerDelegate` callbacks will also not pick them up.

So how to get to them?

**`Ambar` handles this automatically for you!**

Its `CoreDataStack` instance register itself as observer for `NSManagedObjectContextDidSaveNotification` from any context. Then it smartly dismisses any notifications coming from anything except the contexts attached to `writerCoordinator`.

By the power of Core Data, this merge will refresh all objects already loaded in `mainContext` and will ignore all the rest. This gives you the best of all worlds: you can import 1000s of objects in the background and if you are showing just 10 of them, those 10 will be updated and the rest never clog your UI thread.

Additionally, if you smartly chunk out your background import calls, you are free to continually import data – say through web sockets – and never, ever encounter a merge conflict nor experience memory issues.

## Options

```
var isMainContextReadOnly: Bool = false
```

This property will make `mainContext` readonly. If you attempt to save anything in it while this is `true`, those saves will be ignored. If you call `editorContext()` while this is `true`, you app will crash.

```
var shouldMergeIncomingSavedObjects: Bool = true
```

This property allows you to turn off automatic merge between the `importerContext`s and `mainContext`.

