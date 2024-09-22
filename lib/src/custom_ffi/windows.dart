// ignore_for_file: deprecated_member_use

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// Load the appropriate library based on the platform
final msvcrt = DynamicLibrary.open('msvcrt.dll');

// Define the function signature
typedef MemsetNative = Pointer<Void> Function(Pointer<Void>, Int32, Size);

// Define the Dart function signature
typedef Memset = Pointer<Void> Function(Pointer<Void>, int, int);

// Look up the `memset` function
final memsetPointer = msvcrt.lookup<NativeFunction<MemsetNative>>('memset');
final memset = memsetPointer.asFunction<Memset>();

// Define the function signature for memcpy
typedef MemcpyNative = Pointer<Void> Function(Pointer<Void>, Int32, Size);

// Define the Dart function signature
typedef Memcpy = Pointer<Void> Function(Pointer<Void>, int, int);

// Look up the `memcpy` function
final memcpyPointer = msvcrt.lookup<NativeFunction<MemcpyNative>>('memcpy');
final memcpy = memcpyPointer.asFunction<Memcpy>();

// Define the function signature for free
typedef FreeNative = Void Function(Pointer);

// Define the Dart function signature
typedef Free = void Function(Pointer);

// Look up the `free` function
final freePointer = msvcrt.lookup<NativeFunction<FreeNative>>('free');
/// free from msvcrt
final freeStdlib = freePointer.asFunction<Free>();

//typedef WORD = Uint16;
//typedef DWORD = Uint32;
typedef BYTE = Uint8;
typedef ULONGLONG = Uint64;
typedef LPCSTR = Pointer<Utf8>;
//typedef LPVOID = Pointer<Void>;
//typedef SIZE_T = UintPtr;
typedef size_t = Uint64;
typedef PSIZE_T = Pointer<UintPtr>;
//const MEM_RELEASE = 0x8000;
//const int MEM_COMMIT = 0x1000;
//const int PAGE_READWRITE = 0x04;
const IMAGE_FILE_MACHINE_AMD64 = 0x8664;
const IMAGE_SIZEOF_BASE_RELOCATION = 8;
//const IMAGE_BASE_RELOCATION = 8;
const IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16;

// Definindo a estrutura IMAGE_FILE_HEADER
final class IMAGE_FILE_HEADER extends Struct {
  @WORD()
  external int Machine;

  @WORD()
  external int NumberOfSections;

  @DWORD()
  external int TimeDateStamp;

  @DWORD()
  external int PointerToSymbolTable;

  @DWORD()
  external int NumberOfSymbols;

  @WORD()
  external int SizeOfOptionalHeader;

  @WORD()
  external int Characteristics;
}

final class IMAGE_DATA_DIRECTORY extends Struct {
  @DWORD()
  external int VirtualAddress;

  @DWORD()
  external int Size;
}

typedef PIMAGE_DATA_DIRECTORY = Pointer<IMAGE_DATA_DIRECTORY>;

// Definindo a estrutura IMAGE_OPTIONAL_HEADER64
final class IMAGE_OPTIONAL_HEADER64 extends Struct {
  @WORD()
  external int Magic;

  @BYTE()
  external int MajorLinkerVersion;

  @BYTE()
  external int MinorLinkerVersion;

  @Uint32()
  external int SizeOfCode;

  @Uint32()
  external int SizeOfInitializedData;

  @Uint32()
  external int SizeOfUninitializedData;

  @Uint32()
  external int AddressOfEntryPoint;

  @Uint32()
  external int BaseOfCode;

  @Uint64()
  external int ImageBase;

  @Uint32()
  external int SectionAlignment;

  @Uint32()
  external int FileAlignment;

  @Uint16()
  external int MajorOperatingSystemVersion;

  @Uint16()
  external int MinorOperatingSystemVersion;

  @Uint16()
  external int MajorImageVersion;

  @Uint16()
  external int MinorImageVersion;

  @Uint16()
  external int MajorSubsystemVersion;

  @Uint16()
  external int MinorSubsystemVersion;

  @Uint32()
  external int Win32VersionValue;

  @Uint32()
  external int SizeOfImage;

  @Uint32()
  external int SizeOfHeaders;

  @Uint32()
  external int CheckSum;

  @Uint16()
  external int Subsystem;

  @Uint16()
  external int DllCharacteristics;

  @Uint64()
  external int SizeOfStackReserve;

  @Uint64()
  external int SizeOfStackCommit;

  @Uint64()
  external int SizeOfHeapReserve;

  @Uint64()
  external int SizeOfHeapCommit;

  @Uint32()
  external int LoaderFlags;

  @Uint32()
  external int NumberOfRvaAndSizes;

  // Definindo o array DataDirectory
  @Array<IMAGE_DATA_DIRECTORY>(16)
  external Array<IMAGE_DATA_DIRECTORY> DataDirectory;

  factory IMAGE_OPTIONAL_HEADER64.allocate({int sizeOfDataDirectory = 16}) {
    // Crie a estrutura com a alocação do array de ImageDataDirectory
    final struct = calloc<IMAGE_OPTIONAL_HEADER64>();
    return struct.ref;
  }
}

// Definindo a estrutura IMAGE_NT_HEADERS64
// sizeof(PIMAGE_NT_HEADERS) = 8
final class IMAGE_NT_HEADERS64 extends Struct {
  @Uint32()
  external int Signature;

  external IMAGE_FILE_HEADER FileHeader;
  external IMAGE_OPTIONAL_HEADER64 OptionalHeader;
}

typedef IMAGE_NT_HEADERS = IMAGE_NT_HEADERS64;

typedef PIMAGE_NT_HEADERS64 = Pointer<IMAGE_NT_HEADERS64>;

typedef PIMAGE_NT_HEADERS = PIMAGE_NT_HEADERS64;

// Definição da constante do tamanho do nome
const int IMAGE_SIZEOF_SHORT_NAME = 8;

// Definição da estrutura IMAGE_SECTION_HEADER
final class IMAGE_SECTION_HEADER_MISC extends Union {
  @Uint32()
  external int PhysicalAddress;

  @Uint32()
  external int VirtualSize;
}

final class IMAGE_SECTION_HEADER extends Struct {
  @Array(IMAGE_SIZEOF_SHORT_NAME)
  external Array<Uint8> Name;

  external IMAGE_SECTION_HEADER_MISC Misc;

  @Uint32()
  external int VirtualAddress;

  @Uint32()
  external int SizeOfRawData;

  @Uint32()
  external int PointerToRawData;

  @Uint32()
  external int PointerToRelocations;

  @Uint32()
  external int PointerToLinenumbers;

  @Uint16()
  external int NumberOfRelocations;

  @Uint16()
  external int NumberOfLinenumbers;

  @Uint32()
  external int Characteristics;
}

typedef PIMAGE_SECTION_HEADER = Pointer<IMAGE_SECTION_HEADER>;

// Definição da macro IMAGE_FIRST_SECTION equivalente a uma função em Dart
Pointer<IMAGE_SECTION_HEADER> IMAGE_FIRST_SECTION(
    Pointer<IMAGE_NT_HEADERS> ntheaders) {
  // Calcula o deslocamento do campo OptionalHeader dentro de IMAGE_NT_HEADERS
  final optionalHeaderOffset =
      ntheaders.elementAt(1).address - ntheaders.address;

  // Calcula o ponteiro para a primeira seção
  return Pointer<IMAGE_SECTION_HEADER>.fromAddress(ntheaders.address +
      optionalHeaderOffset +
      ntheaders.ref.FileHeader.SizeOfOptionalHeader);
}
