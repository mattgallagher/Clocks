# Clocks
An iOS world-time app written in Swift to demonstrate the benefits of treating view-state as a separate model. The project requires Swift 4 (tested with Xcode 9 beta 6) since it relies on Swift 4's `Codable` functionality.

This project contains two different branches:

* undoredo
* master (aka timetravel)

In either case, the app takes a snapshot every time you make a change and a slider at the bottom of the screen lets you wind
these changes forwards and backwards.

The key difference is that the "undoredo" branch winds back model data only, whereas the timetravel branch winds back model
*and* view-state (together or separately).

The purpose is to demonstrate how much of an app is dependent on view-state rather than the model and show how we can improve
our application by treaing both view-state and model in the same way.
