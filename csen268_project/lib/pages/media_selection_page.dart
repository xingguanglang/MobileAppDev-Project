import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
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
  
  // 任务 3.1：相册权限与初始化
  bool _hasPermission = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 任务 3.2 & 3.3：媒体列表
  List<AssetEntity> _photos = [];
  List<AssetEntity> _videos = [];
  bool _isLoadingMedia = false;
  
  // 任务 3.4：媒体选择（单选）
  AssetEntity? _selectedMedia;
  
  // 分页相关
  int _currentPage = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false; // 防止重复加载
  
  // 相册列表功能
  List<AssetPathEntity> _albums = [];
  bool _isLoadingAlbums = false;
  AssetPathEntity? _selectedAlbum; // 当前选中的相册（用于显示相册详情）
  List<AssetEntity> _albumMedia = []; // 当前相册的媒体列表
  int _albumCurrentPage = 0;
  bool _albumHasMore = true;
  bool _isLoadingAlbumMedia = false;

  @override
  void initState() {
    super.initState();
    _initializePhotoManager();
  }

  // 任务 3.1：相册权限与初始化
  Future<void> _initializePhotoManager() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 请求相册权限
      final PermissionState state = await PhotoManager.requestPermissionExtend();
      
      if (state == PermissionState.authorized || state == PermissionState.limited) {
        // 权限已授予
        setState(() {
          _hasPermission = true;
          _isLoading = false;
        });
        // 加载媒体
        await _loadMedia();
      } else {
        // 权限被拒绝
        setState(() {
          _hasPermission = false;
          _isLoading = false;
          _errorMessage = 'Photo library permission denied. Please enable it in Settings.';
        });
      }
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
        _errorMessage = 'Failed to initialize photo manager: $e';
      });
    }
  }

  // 任务 3.2 & 3.3：加载媒体
  Future<void> _loadMedia({bool loadMore = false}) async {
    // 修复：防止重复加载
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      if (_isLoadingMedia) return;
      setState(() {
        _isLoadingMedia = true;
      });
    }

    try {
      if (_selectedTab == MediaType.photos) {
        await _loadPhotos(loadMore: loadMore);
      } else if (_selectedTab == MediaType.videos) {
        await _loadVideos(loadMore: loadMore);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load media: $e';
      });
    } finally {
      setState(() {
        if (loadMore) {
          _isLoadingMore = false;
        } else {
          _isLoadingMedia = false;
        }
      });
    }
  }

  // 任务 3.2：加载照片
  Future<void> _loadPhotos({bool loadMore = false}) async {
    if (!loadMore) {
      _currentPage = 0;
      _photos.clear();
      _hasMore = true;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    if (albums.isEmpty) {
      setState(() {
        _hasMore = false;
      });
      return;
    }

    // 获取所有照片相册
    final AssetPathEntity recentAlbum = albums.first;
    
    // 修复：使用正确的分页逻辑
    final int start = _currentPage * _pageSize;
    final int end = start + _pageSize;
    
    // 按时间倒序获取照片
    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
      start: start,
      end: end,
    );

    setState(() {
      _photos.addAll(assets);
      _currentPage++;
      // 如果返回的数量少于请求的数量，说明没有更多了
      _hasMore = assets.length == _pageSize;
    });
  }

  // 任务 3.3：加载视频
  Future<void> _loadVideos({bool loadMore = false}) async {
    if (!loadMore) {
      _currentPage = 0;
      _videos.clear();
      _hasMore = true;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      hasAll: true,
    );

    if (albums.isEmpty) {
      setState(() {
        _hasMore = false;
      });
      return;
    }

    // 获取所有视频相册
    final AssetPathEntity recentAlbum = albums.first;
    
    // 修复：使用正确的分页逻辑
    final int start = _currentPage * _pageSize;
    final int end = start + _pageSize;
    
    // 按时间倒序获取视频
    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
      start: start,
      end: end,
    );

    setState(() {
      _videos.addAll(assets);
      _currentPage++;
      // 如果返回的数量少于请求的数量，说明没有更多了
      _hasMore = assets.length == _pageSize;
    });
  }

  // 加载相册列表
  Future<void> _loadAlbums() async {
    if (_isLoadingAlbums) return;

    setState(() {
      _isLoadingAlbums = true;
    });

    try {
      // 获取所有相册（包括照片和视频）
      final List<AssetPathEntity> imageAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );
      
      final List<AssetPathEntity> videoAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: true,
      );

      // 合并相册列表，去重
      final Map<String, AssetPathEntity> albumMap = {};
      
      // 添加照片相册
      for (var album in imageAlbums) {
        albumMap[album.id] = album;
      }
      
      // 添加视频相册
      for (var album in videoAlbums) {
        if (!albumMap.containsKey(album.id)) {
          albumMap[album.id] = album;
        }
      }

      setState(() {
        _albums = albumMap.values.toList();
        _isLoadingAlbums = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load albums: $e';
        _isLoadingAlbums = false;
      });
    }
  }

  // 加载指定相册的媒体
  Future<void> _loadAlbumMedia(AssetPathEntity album, {bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingAlbumMedia || !_albumHasMore) return;
      setState(() {
        _isLoadingAlbumMedia = true;
      });
    } else {
      if (_isLoadingAlbumMedia) return;
      setState(() {
        _isLoadingAlbumMedia = true;
        _albumCurrentPage = 0;
        _albumMedia.clear();
        _albumHasMore = true;
      });
    }

    try {
      final int start = _albumCurrentPage * _pageSize;
      final int end = start + _pageSize;
      
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: start,
        end: end,
      );

      setState(() {
        _albumMedia.addAll(assets);
        _albumCurrentPage++;
        // 如果返回的数量少于请求的数量，说明没有更多了
        _albumHasMore = assets.length == _pageSize;
        _isLoadingAlbumMedia = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load album media: $e';
        _isLoadingAlbumMedia = false;
      });
    }
  }

  // 进入相册详情
  void _enterAlbum(AssetPathEntity album) {
    setState(() {
      _selectedAlbum = album;
      _selectedMedia = null;
    });
    _loadAlbumMedia(album);
  }

  // 返回相册列表
  void _backToAlbums() {
    setState(() {
      _selectedAlbum = null;
      _selectedMedia = null;
      _albumMedia.clear();
      _albumCurrentPage = 0;
      _albumHasMore = true;
    });
  }

  // 切换标签页
  void _switchTab(MediaType type) {
    if (_selectedTab != type) {
      setState(() {
        _selectedTab = type;
        _selectedMedia = null;
        _currentPage = 0;
        _hasMore = true;
        _selectedAlbum = null; // 切换标签时退出相册详情
        _albumMedia.clear();
      });
      
      if (type == MediaType.albums) {
        _loadAlbums();
      } else {
        _loadMedia();
      }
    }
  }

  // 任务 3.4：媒体选择（单选）
  void _selectMedia(AssetEntity asset) {
    setState(() {
      _selectedMedia = asset;
    });
  }

  // 获取相册中的媒体数量
  Future<int> _getAlbumCount(AssetPathEntity album) async {
    try {
      // 获取前1000个来估算数量（photo_manager 没有直接的 count 方法）
      final assets = await album.getAssetListRange(start: 0, end: 1000);
      if (assets.length < 1000) {
        return assets.length;
      }
      // 如果超过1000，返回1000+作为近似值
      return 1000;
    } catch (e) {
      return 0;
    }
  }

  // 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      body: SafeArea(
        child: Column(
          children: [
            // top navigation bar
            _buildTopBar(context),
            // tab switch bar
            _buildTabBar(),
            // media grid content
            Expanded(
              child: _buildMediaContent(),
            ),
            // bottom add button
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
          Row(
            children: [
              // 如果在相册详情页，显示返回按钮；否则显示关闭按钮
              IconButton(
                icon: Icon(
                  _selectedAlbum != null
                      ? (Platform.isIOS ? CupertinoIcons.chevron_left : Icons.arrow_back)
                      : (Platform.isIOS ? CupertinoIcons.xmark : Icons.close),
                  size: 24,
                  color: const Color(0xFF9E9E9E),
                ),
                onPressed: () {
                  if (_selectedAlbum != null) {
                    _backToAlbums();
                  } else {
                    context.pop();
                  }
                },
              ),
              const Spacer(),
              Text(
                _selectedAlbum != null ? _selectedAlbum!.name : 'New Project',
                style: const TextStyle(
                  fontFamily: 'Spline Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C17),
                ),
              ),
              const Spacer(),
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
      onTap: () => _switchTab(type),
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

  Widget _buildMediaContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializePhotoManager,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Photo library permission is required',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedTab == MediaType.albums) {
      // 如果选中了相册，显示相册详情
      if (_selectedAlbum != null) {
        return _buildAlbumMediaGrid();
      }
      // 否则显示相册列表
      return _buildAlbumsList();
    }

    return _buildMediaGrid();
  }

  Widget _buildMediaGrid() {
    final mediaList = _selectedTab == MediaType.photos ? _photos : _videos;

    if (mediaList.isEmpty && !_isLoadingMedia) {
      return Center(
        child: Text(
          _selectedTab == MediaType.photos 
              ? 'No photos found' 
              : 'No videos found',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

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
        itemCount: mediaList.length + (_hasMore && !_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == mediaList.length) {
            // 加载更多指示器
            if (_hasMore && !_isLoadingMore) {
              // 使用 WidgetsBinding 确保在下一帧加载
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMedia(loadMore: true);
              });
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (_isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final asset = mediaList[index];
          final isSelected = _selectedMedia?.id == asset.id;
          
          return _buildMediaItem(asset, isSelected);
        },
      ),
    );
  }

  Widget _buildMediaItem(AssetEntity asset, bool isSelected) {
    final isVideo = asset.type == AssetType.video;

    return GestureDetector(
      onTap: () => _selectMedia(asset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 缩略图
            FutureBuilder<Widget?>(
              future: _buildThumbnail(asset),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return snapshot.data!;
                }
                return _buildPlaceholderImage();
              },
            ),
            // 选中状态覆盖层
            if (isSelected)
              Container(
                color: const Color(0xFF20C978).withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            // 视频播放按钮
            if (isVideo)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: Center(
                  child: Icon(
                    Platform.isIOS ? CupertinoIcons.play_fill : Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            // 视频时长
            if (isVideo)
              FutureBuilder<int>(
                future: Future.value(asset.duration),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! > 0) {
                    final duration = Duration(milliseconds: snapshot.data!);
                    return Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<Widget?> _buildThumbnail(AssetEntity asset) async {
    try {
      final thumbnail = await asset.thumbnailDataWithSize(
        ThumbnailSize(300, 300),
      );
      
      if (thumbnail != null) {
        return Image.memory(
          thumbnail,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
    }
    return null;
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

  // 任务 3.6：Add 按钮功能
  Widget _buildAddButton(BuildContext context) {
    final hasSelection = _selectedMedia != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasSelection ? () => _handleAdd(context) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelection 
                  ? const Color(0xFF20C978) 
                  : Colors.grey[300],
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

  // 任务 3.6：处理添加按钮点击
  Future<void> _handleAdd(BuildContext context) async {
    if (_selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a media item'),
        ),
      );
      return;
    }

    try {
      // 获取媒体文件路径
      final file = await _selectedMedia!.file;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load media file'),
          ),
        );
        return;
      }

      // 将选中的媒体路径传递给 Editor Page
      final selectedPaths = [file.path];
      
      // 导航到编辑器页面
      context.push('/editor', extra: selectedPaths);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  // 构建相册列表
  Widget _buildAlbumsList() {
    if (_isLoadingAlbums) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_albums.isEmpty) {
      return Center(
        child: Text(
          'No albums found',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          final album = _albums[index];
          return _buildAlbumItem(album);
        },
      ),
    );
  }

  // 构建相册项
  Widget _buildAlbumItem(AssetPathEntity album) {
    return FutureBuilder<Widget?>(
      future: _buildAlbumThumbnail(album),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () => _enterAlbum(album),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 相册封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: snapshot.hasData && snapshot.data != null
                        ? snapshot.data!
                        : _buildPlaceholderImage(),
                  ),
                ),
                const SizedBox(width: 16),
                // 相册信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontFamily: 'Spline Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1C17),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: _getAlbumCount(album),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count ${count == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              fontFamily: 'Spline Sans',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Icon(
                  Platform.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建相册封面缩略图
  Future<Widget?> _buildAlbumThumbnail(AssetPathEntity album) async {
    try {
      // 获取相册的第一张图片作为封面
      final assets = await album.getAssetListRange(start: 0, end: 1);
      if (assets.isEmpty) return null;

      final thumbnail = await assets.first.thumbnailDataWithSize(
        ThumbnailSize(200, 200),
      );

      if (thumbnail != null) {
        return Image.memory(
          thumbnail,
          fit: BoxFit.cover,
        );
      }
    } catch (e) {
      print('Error loading album thumbnail: $e');
    }
    return null;
  }

  // 构建相册详情网格（显示相册内的媒体）
  Widget _buildAlbumMediaGrid() {
    if (_albumMedia.isEmpty && !_isLoadingAlbumMedia) {
      return Center(
        child: Text(
          'No media in this album',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

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
        itemCount: _albumMedia.length + (_albumHasMore && !_isLoadingAlbumMedia ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _albumMedia.length) {
            // 加载更多指示器
            if (_albumHasMore && !_isLoadingAlbumMedia) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_selectedAlbum != null) {
                  _loadAlbumMedia(_selectedAlbum!, loadMore: true);
                }
              });
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (_isLoadingAlbumMedia) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final asset = _albumMedia[index];
          final isSelected = _selectedMedia?.id == asset.id;

          return _buildMediaItem(asset, isSelected);
        },
      ),
    );
  }
}
