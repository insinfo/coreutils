import 'package:coreutils/src/cp/windows/windows_ffi.dart';

void main(List<String> args) {
  if (args.length < 2) {
    print('Usage: dartcp [-r] <source> <destination>');
    return;
  }

  final isRecursive = args[0] == '-r';
  final source = isRecursive ? args[1] : args[0];
  final destination = isRecursive ? args[2] : args[1];

  if (isRecursive) {
    copyDirectory(source, destination);
  } else {
    copyFile(source, destination);
  }
}
