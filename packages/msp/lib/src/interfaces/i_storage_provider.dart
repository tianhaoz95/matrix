import 'dart:typed_data';

abstract class IStorageProvider {
  Future<String> uploadFile({
    required String bucketId,
    required String fileId,
    required String name,
    required Uint8List bytes,
  });
  
  Future<Uint8List> getFileDownload({
    required String bucketId,
    required String fileId,
  });
  
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  });
}
