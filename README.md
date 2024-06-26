[![](https://img.shields.io/github/tag/radianttap/Ambar.svg?label=current)](https://github.com/radianttap/Ambar/releases)
![platforms: iOS|tvOS|watchOS|macOS](https://img.shields.io/badge/platform-iOS|tvOS|watchOS|macOS-blue.svg)
[![](https://img.shields.io/github/license/radianttap/Ambar.svg)](https://github.com/radianttap/Ambar/blob/master/LICENSE)\
[![SwiftPM ready](https://img.shields.io/badge/SwiftPM-ready-FA7343.svg?style=flat)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-AD4709.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-fb0006.svg)](https://cocoapods.org)\
![](https://img.shields.io/badge/swift-5-223344.svg?logo=swift&labelColor=FA7343&logoColor=white)

# Ambar

> Noun: ambar (plural ambars)\
> Any of various kinds of subterranean or barn-like granary in Serbia.

AmbarContainer is subclass of `NSPersistentContainer` which implements two separate `NSPersistentStoreCoordinator` instances: one (the system default) for main thread and store reads and another for background imports. If you don’t need this setup, you should use Apple’s `NSPersistentContainer`.

In any case, look into `ManagedObjectType`  —  if your model classes adopt this protocol they will gain several useful methods to fetch data.

### Notes 
- V8 requires iOS 15+ since it uses new Core Data types declared in that version.
- V8 is complete rewrite of the library, aimed at apps using Swift strict concurrency. 
- Main change from version 7 is removal of the setup callbacks. I also removed all references to MOGenerator since I switched to SwiftGen templates a long time ago.

## Installation

Just add this repo’s URL as Swift Package Manager dependency. Use version `8.0.0` or newer.

(Might also be possible to use this through [CocoaPods](https://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage) but I don’t care about those anymore.)

## How to implement 

Create your instance of the `AmbarContainer` in

* main thread
* as early as possible in your app, usually in `application(willFinishLaunching…)` in the AppDelegate.swift

```swift
do {
	coreDataStack = try AmbarContainer(storeURL: url)

} catch let err {
	guard let err = err as? AmbarError else {
		preconditionFailure("Should not happen")
	}
	log(level: .severe, "Failed to setup Core Data store:\n\( err )")
}
```

By default, Ambar uses SQLite store type (personally I have never used anything else).

You can supply the name (no extension) of the specific model you want to use. If you don’t, library will create a model by merging all models it finds in the app bundle.

You can supply a specific directory URL where the `.sqlite` file will be created. This is useful if you are using AppGroups (to share the store with extensions). If you don’t supply it, app will create the store in folder returned by system-provided `NSPersistentContainer.defaultDirectoryURL()` method.

### Main (view) MOC

Since `AmbarContainer` subclasses `NSPersistentContainer`, it already has [`viewContext`](https://developer.apple.com/documentation/coredata/nspersistentcontainer/1640622-viewcontext). You should use this MOC to drive your UI.

This MOC uses merge policy of `.mergeByPropertyStoreTrump` set to favor state of objects in the persistent store (on the disk) versus those in the memory.

If you want to enforce this even further, you can set `isViewContextReadOnly` property to true which will switch mergePolicy to `.rollback` thus silently preventing any store write from the viewContext.

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

This method returns MOC created as child context of the `viewContext` but this time with merge policy that will *override whatever you have in the main MOC* and further along, all the way to the disk.

Textbook usage for this is when you need to create new objects, like new order in shopping app. Since those objects are created in new child MOC, you can freely do whatever in it without influencing objects in main context. If you delete this context, everything goes away, no harm done. If you save this context, everything is automatically propagated to main context first then also further to the disk.

## Killer feature: automatic, smart merge on save

If you have read carefully, you may have noticed that `importerContext` is connected to `writerCoordinator`. This means that objects created in it and later saved to the persistent store will not reach the `viewContext` and thus your UI will have no idea about them.

If you already have some objects loaded in `viewContext` and shown in the UI and those objects are updated through the background import and saved to disk, your UI will have no idea about those changes. Your `NSFetchedResultsControllerDelegate` callbacks will also not pick them up.

So how to get them?

**`Ambar` handles this automatically for you!**

`AmbarContainer` instance register itself as observer for `NSManagedObjectContextDidSaveNotification` from any context. Then it smartly dismisses any notifications coming from anything except the contexts attached to `writerCoordinator`.

By the power of Core Data, this merge will refresh all objects already loaded in `viewContext` and will ignore all the rest. This gives you the best of all worlds: you can import 1000s of objects in the background and if you are showing just 10 of them, those 10 will be updated and the rest never clog your UI thread.

Additionally, if you smartly chunk out your background import calls, you are free to continually import data and don’t encounter a merge conflict nor experience memory issues.

## Give back

If you found this code useful, please consider [buying me a coffee](https://www.buymeacoffee.com/radianttap) or two. ☕️😋
