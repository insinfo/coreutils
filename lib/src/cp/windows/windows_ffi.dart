import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

const MAX_PATH = 260;

// Define the WIN32_FIND_DATAA structure
/// Contains information about the file that is found by the FindFirstFile,
/// FindFirstFileEx, or FindNextFile function.
///
/// {@category struct}
base class WIN32_FIND_DATA extends Struct {
  @Uint32()
  external int dwFileAttributes;

  external FILETIME ftCreationTime;

  external FILETIME ftLastAccessTime;

  external FILETIME ftLastWriteTime;

  @Uint32()
  external int nFileSizeHigh;

  @Uint32()
  external int nFileSizeLow;

  @Uint32()
  external int dwReserved0;

  @Uint32()
  external int dwReserved1;

  @Array(260)
  external Array<Uint16> _cFileName;

  String get cFileName {
    final charCodes = <int>[];
    for (var i = 0; i < 260; i++) {
      if (_cFileName[i] == 0x00) break;
      charCodes.add(_cFileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set cFileName(String value) {
    final stringToStore = value.padRight(260, '\x00');
    for (var i = 0; i < 260; i++) {
      _cFileName[i] = stringToStore.codeUnitAt(i);
    }
  }

  @Array(14)
  external Array<Uint16> _cAlternateFileName;

  String get cAlternateFileName {
    final charCodes = <int>[];
    for (var i = 0; i < 14; i++) {
      if (_cAlternateFileName[i] == 0x00) break;
      charCodes.add(_cAlternateFileName[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  set cAlternateFileName(String value) {
    final stringToStore = value.padRight(14, '\x00');
    for (var i = 0; i < 14; i++) {
      _cAlternateFileName[i] = stringToStore.codeUnitAt(i);
    }
  }
}

extension CharArrayUint8 on Array<Uint8> {
  String getDartString(int maxLength) {
    var list = <int>[];
    for (var i = 0; i < maxLength; i++) {
      if (this[i] != 0) list.add(this[i]);
    }
    return utf8.decode(list);
  }

  void setDartString(String s, int maxLength) {
    var list = utf8.encode(s);
    for (var i = 0; i < maxLength; i++) {
      this[i] = i < list.length ? list[i] : 0;
    }
  }
}

extension CharArrayInt8 on Array<Int8> {
  String getDartString(int maxLength) {
    var list = <int>[];
    for (var i = 0; i < maxLength; i++) {
      if (this[i] != 0) list.add(this[i]);
    }
    return utf8.decode(list);
  }

  void setDartString(String s, int maxLength) {
    var list = utf8.encode(s);
    for (var i = 0; i < maxLength; i++) {
      this[i] = i < list.length ? list[i] : 0;
    }
  }
}

/// Contains a 64-bit value representing the number of 100-nanosecond
/// intervals since January 1, 1601 (UTC).
///
/// {@category struct}
base class FILETIME extends Struct {
  @Uint32()
  external int dwLowDateTime;

  @Uint32()
  external int dwHighDateTime;
}

/// The SECURITY_ATTRIBUTES structure contains the security descriptor for
/// an object and specifies whether the handle retrieved by specifying this
/// structure is inheritable. This structure provides security settings for
/// objects created by various functions, such as CreateFile, CreatePipe,
/// CreateProcess, RegCreateKeyEx, or RegSaveKeyEx.
///
/// {@category struct}
base class SECURITY_ATTRIBUTES extends Struct {
  @Uint32()
  external int nLength;

  external Pointer lpSecurityDescriptor;

  @Int32()
  external int bInheritHandle;
}

// Define as funções nativas
typedef CopyFileC = Int32 Function(
    Pointer<Utf8> source, Pointer<Utf8> dest, Int32 failIfExists);
typedef CopyFileDart = int Function(
    Pointer<Utf8> source, Pointer<Utf8> dest, int failIfExists);

typedef CreateFileC = Int32 Function(
    Pointer<Utf8> lpFileName,
    Uint32 dwDesiredAccess,
    Uint32 dwShareMode,
    Pointer<Void> lpSecurityAttributes,
    Uint32 dwCreationDisposition,
    Uint32 dwFlagsAndAttributes,
    IntPtr hTemplateFile);
typedef CreateFileDart = int Function(
    Pointer<Utf8> lpFileName,
    int dwDesiredAccess,
    int dwShareMode,
    Pointer<Void> lpSecurityAttributes,
    int dwCreationDisposition,
    int dwFlagsAndAttributes,
    int hTemplateFile);

typedef ReadFileC = Int32 Function(
    Int32 hFile,
    Pointer<Void> lpBuffer,
    Uint32 nNumberOfBytesToRead,
    Pointer<Uint32> lpNumberOfBytesRead,
    Pointer<Void> lpOverlapped);
typedef ReadFileDart = int Function(
    int hFile,
    Pointer<Void> lpBuffer,
    int nNumberOfBytesToRead,
    Pointer<Uint32> lpNumberOfBytesRead,
    Pointer<Void> lpOverlapped);

typedef WriteFileC = Int32 Function(
    Int32 hFile,
    Pointer<Void> lpBuffer,
    Uint32 nNumberOfBytesToWrite,
    Pointer<Uint32> lpNumberOfBytesWritten,
    Pointer<Void> lpOverlapped);
typedef WriteFileDart = int Function(
    int hFile,
    Pointer<Void> lpBuffer,
    int nNumberOfBytesToWrite,
    Pointer<Uint32> lpNumberOfBytesWritten,
    Pointer<Void> lpOverlapped);

typedef CloseHandleC = Int32 Function(Int32 hObject);
typedef CloseHandleDart = int Function(int hObject);

const int GENERIC_READ = 0x80000000;
const int GENERIC_WRITE = 0x40000000;
const int OPEN_EXISTING = 3;
const int CREATE_ALWAYS = 2;

// Carrega a biblioteca do sistema
final _kernel32 = DynamicLibrary.open('kernel32.dll');

// Obtém a função CopyFile
/// BOOL CopyFileA(
///  [in] LPCSTR lpExistingFileName,
///  [in] LPCSTR lpNewFileName,
///  [in] BOOL   bFailIfExists
/// );
final _CopyFileAPtr = _kernel32.lookup<NativeFunction<CopyFileC>>('CopyFileA');
final copyFileNative = _CopyFileAPtr.asFunction<CopyFileDart>();

/// Creates or opens a file or I/O device. The most commonly used I/O
/// devices are as follows: file, file stream, directory, physical disk,
/// volume, console buffer, tape drive, communications resource, mailslot,
/// and pipe. The function returns a handle that can be used to access the
/// file or device for various types of I/O depending on the file or device
/// and the flags and attributes specified.
///
/// ```c
/// HANDLE CreateFileW(
///   LPCWSTR               lpFileName,
///   DWORD                 dwDesiredAccess,
///   DWORD                 dwShareMode,
///   LPSECURITY_ATTRIBUTES lpSecurityAttributes,
///   DWORD                 dwCreationDisposition,
///   DWORD                 dwFlagsAndAttributes,
///   HANDLE                hTemplateFile
/// );
/// ```
/// {@category kernel32}
int CreateFile(
        Pointer<Utf16> lpFileName,
        int dwDesiredAccess,
        int dwShareMode,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        int dwCreationDisposition,
        int dwFlagsAndAttributes,
        int hTemplateFile) =>
    _CreateFile(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes,
        dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);

final _CreateFile = _kernel32.lookupFunction<
    IntPtr Function(
        Pointer<Utf16> lpFileName,
        Uint32 dwDesiredAccess,
        Uint32 dwShareMode,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Uint32 dwCreationDisposition,
        Uint32 dwFlagsAndAttributes,
        IntPtr hTemplateFile),
    int Function(
        Pointer<Utf16> lpFileName,
        int dwDesiredAccess,
        int dwShareMode,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        int dwCreationDisposition,
        int dwFlagsAndAttributes,
        int hTemplateFile)>('CreateFileW');

final readFilePtr = _kernel32.lookup<NativeFunction<ReadFileC>>('ReadFile');
final readFile = readFilePtr.asFunction<ReadFileDart>();

final writeFilePtr = _kernel32.lookup<NativeFunction<WriteFileC>>('WriteFile');
final writeFile = writeFilePtr.asFunction<WriteFileDart>();

final closeHandlePtr =
    _kernel32.lookup<NativeFunction<CloseHandleC>>('CloseHandle');
final closeHandle = closeHandlePtr.asFunction<CloseHandleDart>();

typedef CreateDirectoryC = Int32 Function(
    Pointer<Utf8> lpPathName, Pointer<Void> lpSecurityAttributes);
typedef CreateDirectoryDart = int Function(
    Pointer<Utf8> lpPathName, Pointer<Void> lpSecurityAttributes);

typedef FindFirstFileC = Int32 Function(
    Pointer<Utf8> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData);
typedef FindFirstFileDart = int Function(
    Pointer<Utf8> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData);

typedef FindCloseC = Int32 Function(Int32 hFindFile);
typedef FindCloseDart = int Function(int hFindFile);

int CreateDirectory(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes) =>
    _CreateDirectory(lpPathName, lpSecurityAttributes);

final _CreateDirectory = _kernel32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
    int Function(Pointer<Utf16> lpPathName,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>('CreateDirectoryW');

int FindFirstFile(
        Pointer<Utf16> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData) =>
    _FindFirstFile(lpFileName, lpFindFileData);

final _FindFirstFile = _kernel32.lookupFunction<
    IntPtr Function(
        Pointer<Utf16> lpFileName, Pointer<WIN32_FIND_DATA> lpFindFileData),
    int Function(Pointer<Utf16> lpFileName,
        Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindFirstFileW');

int FindNextFile(int hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData) =>
    _FindNextFile(hFindFile, lpFindFileData);

final _FindNextFile = _kernel32.lookupFunction<
    Int32 Function(IntPtr hFindFile, Pointer<WIN32_FIND_DATA> lpFindFileData),
    int Function(int hFindFile,
        Pointer<WIN32_FIND_DATA> lpFindFileData)>('FindNextFileW');

final findClosePtr = _kernel32.lookup<NativeFunction<FindCloseC>>('FindClose');
final findClose = findClosePtr.asFunction<FindCloseDart>();

final getLastErrorPtr =
    _kernel32.lookup<NativeFunction<Int32 Function()>>('GetLastError');
final getLastError = getLastErrorPtr.asFunction<int Function()>();

void handleError(String message) {
  final errorCode = getLastError();
  print('$message (Error code: $errorCode)');
}

bool isValidPath(String path) {
  // Basic checks (you can expand this)
  return path.isNotEmpty && !path.contains('..');
}

const int BUFFER_SIZE = 4096; // Increased buffer size

// Função para copiar arquivos
void copyFile(String source, String dest, {int bufferSize = BUFFER_SIZE}) {
  if (!isValidPath(source) || !isValidPath(dest)) {
    print('Invalid path: $source or $dest');
    return;
  }

  final sourcePtr = source.toNativeUtf16();
  final destPtr = dest.toNativeUtf16();
  final buffer = calloc<Uint8>(BUFFER_SIZE);
  final bytesReadPtr = calloc<Uint32>();
  final bytesWrittenPtr = calloc<Uint32>();
  var sourceHandle = 0;
  var destHandle = 0;
  try {
    sourceHandle =
        CreateFile(sourcePtr, GENERIC_READ, 0, nullptr, OPEN_EXISTING, 0, 0);
    if (sourceHandle == -1) {
      handleError('Error opening source file: $source');
      return;
    }

    destHandle =
        CreateFile(destPtr, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, 0, 0);
    if (destHandle == -1) {
      closeHandle(sourceHandle);
      handleError('Error opening destination file: $dest');
      return;
    }

    int bytesRead;
    do {
      if (readFile(sourceHandle, buffer.cast<Void>(), bufferSize, bytesReadPtr,
              nullptr) ==
          0) {
        handleError('Error reading source file.');
        break;
      }

      bytesRead = bytesReadPtr.value;

      if (bytesRead > 0) {
        if (writeFile(destHandle, buffer.cast<Void>(), bytesRead,
                bytesWrittenPtr, nullptr) ==
            0) {
          handleError('Error writing to destination file.');
          break;
        }
      }
    } while (bytesRead > 0);
  } finally {
    calloc.free(buffer);
    calloc.free(bytesReadPtr);
    calloc.free(bytesWrittenPtr);
    closeHandle(sourceHandle);
    closeHandle(destHandle);
  }

  print('File copied from $source to $dest successfully.');
}

void copyDirectory(String sourceDir, String destDir) {
  final findData = calloc<WIN32_FIND_DATA>();

  if (CreateDirectory(destDir.toNativeUtf16(), nullptr) == 0) {
    print('Error creating destination directory: $destDir');
  }

  final searchPattern = '$sourceDir\\*';
  final handle = FindFirstFile(searchPattern.toNativeUtf16(), findData);

  if (handle == -1) {
    print('Error finding files in directory: $sourceDir');
    return;
  }

  do {
    // final fileName = .cast<Utf8>().toDartString();

    final fileName = findData.ref.cFileName;

    if (fileName != '.' && fileName != '..') {
      final sourcePath = '$sourceDir\\$fileName';
      final destPath = '$destDir\\$fileName';

      if (findData.ref.dwFileAttributes & 0x10 != 0) {
        // Check if it's a directory
        copyDirectory(sourcePath, destPath);
      } else {
        copyFile(sourcePath, destPath);
      }
    }
  } while (FindNextFile(handle, findData.cast()) != 0);

  findClose(handle);
  calloc.free(findData);
  print('Directory copied from $sourceDir to $destDir successfully.');
}
