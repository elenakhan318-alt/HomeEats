import 'package:flutter/material.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    required this.title,
    required this.description,
    required this.icon,
    this.onUpload,
    this.fileName,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.onRemove,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? fileName;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback? onUpload;
  final VoidCallback? onRemove;

bool get hasFile =>
    fileName != null && fileName!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  hasFile
                      ? Icons.check_circle_rounded
                      : Icons.pending_outlined,
                  color: hasFile
                      ? Colors.green
                      : Theme.of(context)
                          .colorScheme
                          .outline,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isUploading) ...[
              LinearProgressIndicator(
                value: uploadProgress > 0
                    ? uploadProgress
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                uploadProgress > 0
                    ? 'Uploading ${(uploadProgress * 100).round()}%'
                    : 'Preparing upload...',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (hasFile) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.upload_file_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No file uploaded',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        isUploading ? null : onUpload,
                    icon: Icon(
                      hasFile
                          ? Icons.change_circle_outlined
                          : Icons.upload_file_outlined,
                    ),
                    label: Text(
                      hasFile
                          ? 'Replace file'
                          : 'Choose file',
                    ),
                  ),
                ),
                if (hasFile && onRemove != null) ...[
  const SizedBox(width: 10),
  OutlinedButton.icon(
    onPressed:
        isUploading ? null : onRemove,
    icon: const Icon(
      Icons.delete_outline_rounded,
    ),
    label: const Text('Remove'),
  ),
],
              ],
            ),
          ],
        ),
      ),
    );
  }
}