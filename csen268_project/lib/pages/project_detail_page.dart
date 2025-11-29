import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csen268_project/cubits/project_cubit.dart';

class ProjectDetailPage extends StatelessWidget {
  final String projectId;
  final String? imageUrl;
  const ProjectDetailPage({
    Key? key,
    required this.projectId,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('ProjectDetailPage project.id: $projectId');
    final displayUrl = imageUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Image'),
        backgroundColor: const Color(0xFFF7FBF9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Image.asset('assets/icons/delete.png', width: 24, height: 24),
            onPressed: () async {
              // call the Cubit to delete the project
              await context.read<ProjectCubit>().deleteProject(projectId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project deleted')),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7FBF9),
      body: Center(
        child: displayUrl != null
            ? InteractiveViewer(
                child: displayUrl.startsWith('http')
                    ? Image.network(
                        displayUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      )
                    : Image.file(
                        File(displayUrl),
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
