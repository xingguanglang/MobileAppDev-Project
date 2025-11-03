import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;

enum MediaType {
  videos,
  photos,
  albums,
}

class MediaSelectionPage extends StatefulWidget {
  const MediaSelectionPage({super.key});

  @override
  State<MediaSelectionPage> createState() => _MediaSelectionPageState();
}

class _MediaSelectionPageState extends State<MediaSelectionPage> {
  MediaType _selectedTab = MediaType.photos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(context),
            // Tab切换栏
            _buildTabBar(),
            // 媒体网格内容
            Expanded(
              child: _buildMediaGrid(),
            ),
            // 底部Add按钮
            _buildAddButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Selection 副标题
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Media Selection',
              style: TextStyle(
                fontFamily: 'Spline Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          // 顶部栏：关闭按钮 + New Project标题
          Row(
            children: [
              // 左侧关闭按钮
              IconButton(
                icon: Icon(
                  Platform.isIOS ? CupertinoIcons.xmark : Icons.close,
                  size: 24,
                  color: const Color(0xFF9E9E9E),
                ),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              // 中间标题
              const Text(
                'New Project',
                style: TextStyle(
                  fontFamily: 'Spline Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C17),
                ),
              ),
              const Spacer(),
              // 右侧占位（保持居中）
              SizedBox(
                width: 48,
                height: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildTabItem('Videos', MediaType.videos),
          const SizedBox(width: 24),
          _buildTabItem('Photos', MediaType.photos),
          const SizedBox(width: 24),
          _buildTabItem('Albums', MediaType.albums),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, MediaType type) {
    final isSelected = _selectedTab == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = type;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Spline Sans',
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? const Color(0xFF20C978) : const Color(0xFF0D1C17),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: label.length * 8.0,
            height: 2,
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF20C978) 
                  : const Color(0xFF20C978).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    // 占位数据 - 后续可替换为真实数据
    final mediaItems = _getMediaItems();
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final item = mediaItems[index];
          return _buildMediaItem(item);
        },
      ),
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    return GestureDetector(
      onTap: () {
        // TODO: 处理媒体项点击
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 图片/视频缩略图占位符
            Container(
              color: Colors.grey[300],
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            // 如果是视频，显示播放按钮覆盖层
            if (item.isVideo)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Icon(
                    Platform.isIOS ? CupertinoIcons.play_fill : Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            // 视频时长标签（可选）
            if (item.isVideo && item.duration != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.duration!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Platform.isIOS ? CupertinoIcons.photo : Icons.image,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // TODO: 处理Add按钮点击
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20C978),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.2),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Spline Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 占位数据 - 后续可替换为真实数据源
  List<MediaItem> _getMediaItems() {
    // 这里返回示例数据，后续可以连接到真实的媒体库
    return [
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: true, imageUrl: null, duration: '2:34'),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
      MediaItem(isVideo: false, imageUrl: null),
    ];
  }
}

// 简单的媒体项数据模型
class MediaItem {
  final bool isVideo;
  final String? imageUrl;
  final String? duration;

  MediaItem({
    required this.isVideo,
    this.imageUrl,
    this.duration,
  });
}

