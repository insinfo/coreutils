import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Definições de funções da libc
typedef OpenC = Int32 Function(Pointer<Utf8> pathname, Int32 flags, Int32 mode);
typedef OpenDart = int Function(Pointer<Utf8> pathname, int flags, int mode);

typedef ReadC = Int32 Function(Int32 fd, Pointer<Void> buf, Int32 count);
typedef ReadDart = int Function(int fd, Pointer<Void> buf, int count);

typedef WriteC = Int32 Function(Int32 fd, Pointer<Void> buf, Int32 count);
typedef WriteDart = int Function(int fd, Pointer<Void> buf, int count);

typedef CloseC = Int32 Function(Int32 fd);
typedef CloseDart = int Function(int fd);

const int O_RDONLY = 0;
const int O_WRONLY = 1;
const int O_CREAT = 64;
const int O_TRUNC = 512;
const int S_IRUSR = 256; // Read permission for owner
const int S_IWUSR = 128; // Write permission for owner

// Carrega a biblioteca C
final _libc = DynamicLibrary.open('libc.so.6');

// Carrega as funções necessárias
final openPtr = _libc.lookup<NativeFunction<OpenC>>('open');
final open = openPtr.asFunction<OpenDart>();

final readPtr = _libc.lookup<NativeFunction<ReadC>>('read');
final read = readPtr.asFunction<ReadDart>();

final writePtr = _libc.lookup<NativeFunction<WriteC>>('write');
final write = writePtr.asFunction<WriteDart>();

final closePtr = _libc.lookup<NativeFunction<CloseC>>('close');
final close = closePtr.asFunction<CloseDart>();

void copyFile(String source, String dest) {
  // Converte strings Dart para C
  final sourcePtr = source.toNativeUtf8();
  final destPtr = dest.toNativeUtf8();

  // Abre o arquivo de origem
  final sourceFd = open(sourcePtr, O_RDONLY, 0);
  if (sourceFd < 0) {
    print('Erro ao abrir o arquivo de origem: $source');
    return;
  }

  // Abre ou cria o arquivo de destino
  final destFd = open(destPtr, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
  if (destFd < 0) {
    close(sourceFd);
    print('Erro ao abrir o arquivo de destino: $dest');
    return;
  }

  // Buffer para leitura
  final buffer = calloc<Uint8>(1024); // 1KB de buffer
  int bytesRead;
  do {
    bytesRead = read(sourceFd, buffer.cast<Void>(), 1024);
    if (bytesRead > 0) {
      write(destFd, buffer.cast<Void>(), bytesRead);
    }
  } while (bytesRead > 0);

  // Libera a memória
  calloc.free(buffer);
  close(sourceFd);
  close(destFd);

  print('Arquivo copiado de $source para $dest com sucesso.');
}
