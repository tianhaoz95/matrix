import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import '../interfaces/i_storage_provider.dart';

class AppwriteStorageProvider implements IStorageProvider {
  final Client client;
  final Storage _storage;

  AppwriteStorageProvider(this.client) : _storage = Storage(client);

  @override
  Future<String> uploadFile({
    required String bucketId,
    required String fileId,
    required String name,
    required Uint8List bytes,
  }) async {
    final file = await _storage.createFile(
      bucketId: bucketId,
      fileId: fileId,
      file: InputFile.fromBytes(bytes: bytes, filename: name),
    );
    return file.$id;
  }

  @override
  Future<Uint8List> getFileDownload({
    required String bucketId,
    required String fileId,
  }) async {
    return await _storage.getFileDownload(
      bucketId: bucketId,
      fileId: fileId,
    );
  }

  @override
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    await _storage.deleteFile(
      bucketId: bucketId,
      fileId: fileId,
    );
  }
}
