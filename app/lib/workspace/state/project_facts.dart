// What a saved project says about itself, read without opening it: the home screen shows it on each card.
import 'package:motolii/bridge/motolii.dart' show docFactsOf;

/// A project's size in pixels, its length in seconds and its frame rate, as it last saved them.
typedef ProjectFacts = ({int wide, int high, double seconds, double rate});

/// Reads the facts saved in the project at [projectPath], on another isolate of the engine at [lib], and writes its
/// picture to [picturePath]. Null if the project saved none or is not a project.
Future<ProjectFacts?> savedProjectFacts(
  String lib,
  String projectPath,
  String picturePath,
) => docFactsOf(lib, projectPath, picturePath);
