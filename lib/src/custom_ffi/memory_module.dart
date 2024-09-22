// ignore_for_file: deprecated_member_use

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'windows.dart';

typedef HMEMORYMODULE = Pointer<Void>;
typedef HMEMORYRSRC = Pointer<Void>;
typedef HCUSTOMMODULE = Pointer<Void>;

final class ExportNameEntry extends Struct {
  external LPCSTR name;
  @Uint16()
  external int idx;
}

final class POINTER_LIST extends Struct {
  external Pointer<POINTER_LIST> next;
  external Pointer<Void> address;
}

//typedef LPVOID (*CustomAllocFunc)(LPVOID, SIZE_T, DWORD, DWORD, void *);
typedef CustomAllocFuncDart = LPVOID Function(
    LPVOID, int, int, int, Pointer<Void>);

typedef CustomAllocFuncNat = LPVOID Function(
    LPVOID, SIZE_T, DWORD, DWORD, Pointer<Void>);

// Definindo o CustomFreeFunc
typedef CustomFreeFunc = int Function(
    LPVOID address, int zero, int memRelease, Pointer<Void> userdata);
typedef CustomFreeFuncNat = BOOL Function(
    LPVOID address, SIZE_T zero, DWORD memRelease, Pointer<Void> userdata);

typedef CustomFreeLibraryFunc = Void Function(HCUSTOMMODULE, Pointer<Void>);
typedef CustomLoadLibraryFunc = HCUSTOMMODULE Function(LPCSTR, Pointer<Void>);

typedef FARPROC = INT_PTR Function();
typedef FARPROCNat = INT_PTR Function();

// Definindo os tipos
typedef WINAPI = Int32 Function(); // Definindo a convenção de chamada
typedef ExeEntryProc = Int32 Function(); // Typedef do Dart

typedef CustomGetProcAddressFunc = FARPROC Function(
    HCUSTOMMODULE, LPCSTR, Pointer<Void>);

final class MEMORYMODULE extends Struct {
  external PIMAGE_NT_HEADERS headers; // PIMAGE_NT_HEADERS
  external Pointer<Uint8> codeBase;
  external Pointer<HCUSTOMMODULE> modules; // HCUSTOMMODULE*
  @Int32()
  external int numModules;
  @Bool()
  external bool initialized;
  @Bool()
  external bool isDLL;
  @Bool()
  external bool isRelocated;
  // CustomAllocFunc
  external Pointer<NativeFunction<CustomAllocFuncNat>> alloc;
  // CustomFreeFunc
  external Pointer<NativeFunction<CustomFreeFuncNat>> free;
  external Pointer<NativeFunction<CustomLoadLibraryFunc>> loadLibrary;
  // CustomGetProcAddressFunc
  external Pointer<NativeFunction<CustomGetProcAddressFunc>> getProcAddress;
  // CustomFreeLibraryFunc
  external Pointer<NativeFunction<CustomFreeLibraryFunc>> freeLibrary;
  // struct ExportNameEntry*
  external Pointer<ExportNameEntry> nameExportsTable;
  external Pointer<Void> userdata;
  // ExeEntryProc
  external Pointer<NativeFunction<Void Function()>> exeEntry;

  @DWORD()
  external int pageSize;

  // For _WIN64 specific field
  // POINTER_LIST*, assumed 64-bit compatibility
  external Pointer<POINTER_LIST> blockedMemory;
}

typedef PMEMORYMODULE = Pointer<MEMORYMODULE>;

final class SECTIONFINALIZEDATA extends Struct {
  external LPVOID address;
  external LPVOID alignedAddress;
  @SIZE_T()
  external int size;
  @DWORD()
  external int characteristics;
  @BOOL()
  external int last;
}

typedef PSECTIONFINALIZEDATA = Pointer<SECTIONFINALIZEDATA>;

void FreePointerList(
    Pointer<POINTER_LIST> head,
    Pointer<NativeFunction<CustomFreeFuncNat>> freeMemory,
    Pointer<Void> userdata) {
  var node = head;
  final freeMemoryDart = freeMemory.asFunction<CustomFreeFunc>();

  while (node.address != nullptr.address) {
    // Chame a função de liberação de memória personalizada
    freeMemoryDart(node.ref.address, 0, MEM_RELEASE, userdata);

    // Avance para o próximo nó
    final next = node.ref.next;

    // Libere a memória para o nó atual
    freeStdlib(node);

    // Avance para o próximo nó na lista
    node = next;
  }
}

bool CheckSize(int size, int expected) {
  if (size < expected) {
    //SetLastError(ERROR_INVALID_DATA);
    print('CheckSize ERROR_INVALID_DATA');
    return false;
  }
  return true;
}

bool CopySections(Pointer<Uint8> data, int size, PIMAGE_NT_HEADERS old_headers,
    PMEMORYMODULE module) {
  int i, sectionSize = 0;
  Pointer<Uint8> codeBase = module.ref.codeBase;
  Pointer<Uint8> dest;

  PIMAGE_SECTION_HEADER section = IMAGE_FIRST_SECTION(module.ref.headers);
  final numberOfSections = module.ref.headers.ref.FileHeader.NumberOfSections;

  final customAllocFunc = module.ref.alloc.asFunction<CustomAllocFuncDart>();

  //section++ =  section = section.elementAt(1)
  for (i = 0; i < numberOfSections; i++, section++) {
    if (section.ref.SizeOfRawData == 0) {
      // section doesn't contain data in the dll itself, but may define
      // uninitialized data
      sectionSize = old_headers.ref.OptionalHeader.SectionAlignment;
      if (sectionSize > 0) {
        dest = customAllocFunc(codeBase.elementAt(section.ref.VirtualAddress),
                sectionSize, MEM_COMMIT, PAGE_READWRITE, module.ref.userdata)
            .cast();

        if (dest.address == nullptr.address) {
          return false; // FALSE
        }
        // Always use position from file to support alignments smaller
        // than page size (allocation above will align to page size).
        dest = codeBase.elementAt(section.ref.VirtualAddress);

        section.ref.Misc.PhysicalAddress = dest.address & 0xffffffff;
        memset(dest.cast(), 0, sectionSize);
      }
      continue;
    }

    if (!CheckSize(
        size, section.ref.PointerToRawData + section.ref.SizeOfRawData)) {
      return false; // FALSE
    }

    dest = customAllocFunc(
            codeBase.elementAt(section.ref.VirtualAddress),
            section.ref.SizeOfRawData,
            MEM_COMMIT,
            PAGE_READWRITE,
            module.ref.userdata)
        .cast();
    if (dest.address == nullptr.address) {
      return false; // FALSE
    }

    dest = codeBase.elementAt(section.ref.VirtualAddress);

    section.ref.Misc.PhysicalAddress = dest.address & 0xffffffff;

    memcpy(dest.cast(), 0, sectionSize);
  }

  return true;
}
