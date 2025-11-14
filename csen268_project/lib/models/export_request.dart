enum ExportMediaType { photo, video }

class ExportRequest {
  final String filePath;
  final ExportMediaType mediaType;
  final Duration? duration;

  const ExportRequest({
    required this.filePath,
    required this.mediaType,
    this.duration,
  });

  bool get isVideo => mediaType == ExportMediaType.video;
  bool get isPhoto => mediaType == ExportMediaType.photo;
}
