import 'package:flutter/material.dart';

class ProjectDetailPage extends StatelessWidget {
  final String? imageUrl;
  const ProjectDetailPage({Key? key, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Image'),
        backgroundColor: const Color(0xFFF7FBF9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF7FBF9),
      body: Center(
        child: imageUrl != null
            ? InteractiveViewer(
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              )
            : const Text('No image available'),
      ),
    );
  }
}
