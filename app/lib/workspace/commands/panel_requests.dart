// Requests one panel makes of another: the timeline's view, a rename, the render and size boxes, the shelf search.
//
// Each is a notifier the asked panel listens to, so no panel imports the panel it asks.
import 'package:flutter/foundation.dart' show ValueNotifier;

/// A request to the timeline about its own view: zoom or loop. The timeline keeps that state itself.
///
/// The string names the request and the int counts requests so that repeating one still notifies listeners.
final wsTimelineAsk = ValueNotifier<(String, int)>(('', 0));
void wsAskTimeline(String what) => wsTimelineAsk.value = (what, wsTimelineAsk.value.$2 + 1);

/// Asks the selected layer's row to start renaming (Live 42.5 and 42.19: Cmd+R renames).
final wsAskRename = ValueNotifier<int>(0);

/// The marker (locator) selected by a click on its flag, as its time and name.
///
/// Cmd+R renames it and Delete removes it (Live 6.4: a locator is selected, then renamed or deleted like anything else).
final wsMarkPicked = ValueNotifier<(double, String)?>(null);

/// Cmd+R and the Render button both open the export settings before a video is written.
final wsAskRender = ValueNotifier<int>(0);

/// Set to true to open the size box once the window shows a new project, as Alight Motion's new-project box comes first.
/// The chip resets it to false when it opens the box.
final wsAskSize = ValueNotifier<bool>(false);

/// Bumped when another panel (the Inspector's Add Effect) asks for the search field to take focus.
///
/// The search field on screen takes focus. If there is none yet, the next one to be built does.
final dockSearchAsked = ValueNotifier(0);

/// Whether a request is still waiting for a search field to be built.
bool dockSearchAwaited = false;

/// Asks the shelf's search field to take focus and select its text.
void askDockSearch() {
  dockSearchAwaited = true;
  dockSearchAsked.value++;
}
