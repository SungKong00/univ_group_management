import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/file_upload_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enums for convenience
export '../theme/enums.dart'
    show AppFileUploadType, AppFileUploadStatus, AppFileUploadSize;

/// 업로드된 파일 정보
class UploadedFile {
  /// 파일 이름
  final String name;

  /// 파일 크기 (bytes)
  final int size;

  /// 파일 MIME 타입
  final String? mimeType;

  /// 업로드 상태
  final AppFileUploadStatus status;

  /// 업로드 진행률 (0.0 - 1.0)
  final double progress;

  /// 에러 메시지
  final String? errorMessage;

  /// 파일 아이콘 (선택)
  final IconData? icon;

  const UploadedFile({
    required this.name,
    required this.size,
    this.mimeType,
    this.status = AppFileUploadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
    this.icon,
  });

  /// 업로드 상태 복사 생성자
  UploadedFile copyWith({
    String? name,
    int? size,
    String? mimeType,
    AppFileUploadStatus? status,
    double? progress,
    String? errorMessage,
    IconData? icon,
  }) {
    return UploadedFile(
      name: name ?? this.name,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      icon: icon ?? this.icon,
    );
  }
}

/// 파일 업로드 컴포넌트
///
/// **용도**: 이미지, 문서, 파일 업로드
/// **접근성**: 키보드 네비게이션, 드래그 앤 드롭 지원
/// **반응형**: 화면 크기에 맞게 자동 조정
///
/// ```dart
/// // 단일 파일 업로드
/// AppFileUpload(
///   type: AppFileUploadType.single,
///   onFilesSelected: (files) => _handleFiles(files),
/// )
///
/// // 다중 파일 업로드
/// AppFileUpload(
///   type: AppFileUploadType.multiple,
///   maxFiles: 5,
///   allowedExtensions: ['jpg', 'png', 'pdf'],
///   onFilesSelected: (files) => _handleFiles(files),
/// )
///
/// // 드래그 앤 드롭 영역
/// AppFileUpload(
///   type: AppFileUploadType.dropzone,
///   selectedFiles: _uploadedFiles,
///   onFilesSelected: (files) => _handleFiles(files),
///   onFileRemoved: (file) => _removeFile(file),
/// )
/// ```
class AppFileUpload extends StatefulWidget {
  /// 업로드 타입
  final AppFileUploadType type;

  /// 컴포넌트 크기
  final AppFileUploadSize size;

  /// 허용된 확장자 목록 (예: ['jpg', 'png', 'pdf'])
  final List<String>? allowedExtensions;

  /// 최대 파일 개수
  final int? maxFiles;

  /// 최대 파일 크기 (bytes)
  final int? maxFileSize;

  /// 파일 선택 콜백
  final ValueChanged<List<UploadedFile>>? onFilesSelected;

  /// 파일 제거 콜백
  final ValueChanged<UploadedFile>? onFileRemoved;

  /// 선택된 파일 목록
  final List<UploadedFile>? selectedFiles;

  /// 업로드 상태
  final AppFileUploadStatus status;

  /// 업로드 진행률 (0.0 - 1.0)
  final double? uploadProgress;

  /// 비활성화 상태
  final bool isDisabled;

  /// 에러 메시지
  final String? errorText;

  /// 라벨 텍스트
  final String? label;

  /// 헬퍼 텍스트
  final String? helperText;

  /// 업로드 영역 제목
  final String? uploadTitle;

  /// 업로드 영역 설명
  final String? uploadDescription;

  const AppFileUpload({
    super.key,
    this.type = AppFileUploadType.single,
    this.size = AppFileUploadSize.medium,
    this.allowedExtensions,
    this.maxFiles,
    this.maxFileSize,
    this.onFilesSelected,
    this.onFileRemoved,
    this.selectedFiles,
    this.status = AppFileUploadStatus.idle,
    this.uploadProgress,
    this.isDisabled = false,
    this.errorText,
    this.label,
    this.helperText,
    this.uploadTitle,
    this.uploadDescription,
  });

  @override
  State<AppFileUpload> createState() => _AppFileUploadState();
}

class _AppFileUploadState extends State<AppFileUpload> {
  bool _isDragOver = false;
  bool _isHovered = false;

  void _handleDragEnter() {
    if (widget.isDisabled) return;
    setState(() => _isDragOver = true);
  }

  void _handleDragLeave() {
    setState(() => _isDragOver = false);
  }

  void _handleDrop() {
    setState(() => _isDragOver = false);
    // 실제 구현에서는 드래그된 파일 처리
    _simulateFileSelection();
  }

  void _handleTap() {
    if (widget.isDisabled) return;
    // 실제 구현에서는 파일 선택 다이얼로그 표시
    _simulateFileSelection();
  }

  void _simulateFileSelection() {
    // 데모용: 실제 구현에서는 file_picker 패키지 사용
    final mockFile = UploadedFile(
      name: 'example_file.pdf',
      size: 1024 * 1024 * 2, // 2MB
      mimeType: 'application/pdf',
      status: AppFileUploadStatus.completed,
      progress: 1.0,
    );
    widget.onFilesSelected?.call([mockFile]);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getDefaultTitle() {
    return switch (widget.type) {
      AppFileUploadType.single => '파일 선택',
      AppFileUploadType.multiple => '파일 선택',
      AppFileUploadType.dropzone => '파일을 드래그하거나 클릭하여 업로드',
    };
  }

  String _getDefaultDescription() {
    final parts = <String>[];

    if (widget.allowedExtensions != null) {
      parts.add('허용: ${widget.allowedExtensions!.join(', ')}');
    }

    if (widget.maxFileSize != null) {
      parts.add('최대 ${_formatFileSize(widget.maxFileSize!)}');
    }

    if (widget.maxFiles != null) {
      parts.add('최대 ${widget.maxFiles}개');
    }

    return parts.isEmpty ? '모든 파일 형식 지원' : parts.join(' • ');
  }

  double _getDropzoneHeight() {
    return switch (widget.size) {
      AppFileUploadSize.small => 120.0,
      AppFileUploadSize.medium => 160.0,
      AppFileUploadSize.large => 200.0,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      AppFileUploadSize.small => ComponentSizeTokens.iconMedium,
      AppFileUploadSize.medium => ComponentSizeTokens.iconLarge,
      AppFileUploadSize.large => 40.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = FileUploadColors.from(colorExt);

    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: widget.isDisabled ? colors.textDisabled : colors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacingExt.small),
        ],

        // 업로드 영역
        _buildUploadArea(colors, spacingExt, hasError),

        // 헬퍼/에러 텍스트
        if (widget.helperText != null || hasError) ...[
          SizedBox(height: spacingExt.xs),
          Text(
            hasError ? widget.errorText! : widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: hasError ? colors.textError : colors.textSecondary,
            ),
          ),
        ],

        // 선택된 파일 목록
        if (widget.selectedFiles != null &&
            widget.selectedFiles!.isNotEmpty) ...[
          SizedBox(height: spacingExt.medium),
          _buildFileList(colors, spacingExt),
        ],
      ],
    );
  }

  Widget _buildUploadArea(
    FileUploadColors colors,
    AppSpacingExtension spacingExt,
    bool hasError,
  ) {
    final backgroundColor = widget.isDisabled
        ? colors.background
        : _isDragOver
        ? colors.backgroundDragOver
        : _isHovered
        ? colors.backgroundHover
        : colors.background;

    final borderColor = hasError
        ? colors.borderError
        : widget.isDisabled
        ? colors.borderDisabled
        : _isDragOver
        ? colors.borderDragOver
        : _isHovered
        ? colors.borderHover
        : colors.border;

    final iconColor = widget.isDisabled
        ? colors.iconDisabled
        : _isDragOver
        ? colors.iconDragOver
        : colors.icon;

    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : _handleTap,
        child: DragTarget<Object>(
          onWillAcceptWithDetails: (_) {
            _handleDragEnter();
            return !widget.isDisabled;
          },
          onLeave: (_) => _handleDragLeave(),
          onAcceptWithDetails: (_) => _handleDrop(),
          builder: (context, candidateData, rejectedData) {
            return AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              height: _getDropzoneHeight(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
                border: Border.all(
                  color: borderColor,
                  width: _isDragOver
                      ? BorderTokens.widthFocus
                      : BorderTokens.widthThin,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AnimationTokens.durationQuick,
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: _getIconSize(),
                        color: iconColor,
                      ),
                    ),
                    SizedBox(height: spacingExt.small),
                    Text(
                      widget.uploadTitle ?? _getDefaultTitle(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: widget.isDisabled
                            ? colors.textDisabled
                            : colors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: spacingExt.xs),
                    Text(
                      widget.uploadDescription ?? _getDefaultDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isDisabled
                            ? colors.textDisabled
                            : colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileList(
    FileUploadColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return Column(
      children: widget.selectedFiles!.map((file) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacingExt.small),
          child: _FileItem(
            file: file,
            colors: colors,
            spacingExt: spacingExt,
            onRemove: widget.onFileRemoved != null
                ? () => widget.onFileRemoved!(file)
                : null,
            formatFileSize: _formatFileSize,
          ),
        );
      }).toList(),
    );
  }
}

/// 파일 아이템 위젯
class _FileItem extends StatefulWidget {
  final UploadedFile file;
  final FileUploadColors colors;
  final AppSpacingExtension spacingExt;
  final VoidCallback? onRemove;
  final String Function(int) formatFileSize;

  const _FileItem({
    required this.file,
    required this.colors,
    required this.spacingExt,
    required this.formatFileSize,
    this.onRemove,
  });

  @override
  State<_FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<_FileItem> {
  bool _isHovered = false;

  IconData _getFileIcon(String? mimeType, String name) {
    if (widget.file.icon != null) return widget.file.icon!;

    final extension = name.split('.').last.toLowerCase();

    // MIME 타입 기반
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return Icons.image_outlined;
      if (mimeType.startsWith('video/')) return Icons.video_file_outlined;
      if (mimeType.startsWith('audio/')) return Icons.audio_file_outlined;
      if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    }

    // 확장자 기반
    return switch (extension) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'xls' || 'xlsx' => Icons.table_chart_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'zip' || 'rar' || '7z' => Icons.folder_zip_outlined,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_outlined,
      'mp4' || 'avi' || 'mov' => Icons.video_file_outlined,
      'mp3' || 'wav' || 'flac' => Icons.audio_file_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.file.status == AppFileUploadStatus.uploading;
    final isError = widget.file.status == AppFileUploadStatus.error;
    final isCompleted = widget.file.status == AppFileUploadStatus.completed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AnimationTokens.durationQuick,
        padding: EdgeInsets.all(widget.spacingExt.small),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.colors.itemBackgroundHover
              : widget.colors.itemBackground,
          borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          border: Border.all(
            color: isError
                ? widget.colors.borderError
                : widget.colors.itemBorder,
            width: BorderTokens.widthThin,
          ),
        ),
        child: Row(
          children: [
            // 파일 아이콘
            Icon(
              _getFileIcon(widget.file.mimeType, widget.file.name),
              size: ComponentSizeTokens.iconMedium,
              color: isError
                  ? widget.colors.textError
                  : widget.colors.textSecondary,
            ),
            SizedBox(width: widget.spacingExt.small),

            // 파일 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.file.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.colors.text,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        widget.formatFileSize(widget.file.size),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.colors.textSecondary,
                        ),
                      ),
                      if (isError && widget.file.errorMessage != null) ...[
                        Text(
                          ' • ',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: widget.colors.textSecondary),
                        ),
                        Expanded(
                          child: Text(
                            widget.file.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: widget.colors.textError),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // 프로그레스 바
                  if (isUploading) ...[
                    SizedBox(height: widget.spacingExt.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        BorderTokens.radiusSmall,
                      ),
                      child: LinearProgressIndicator(
                        value: widget.file.progress,
                        backgroundColor: widget.colors.progressBarBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.colors.progressBar,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: widget.spacingExt.small),

            // 상태 아이콘 또는 삭제 버튼
            if (isUploading)
              SizedBox(
                width: ComponentSizeTokens.iconSmall,
                height: ComponentSizeTokens.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.colors.progressBar,
                  ),
                ),
              )
            else if (isCompleted && widget.onRemove == null)
              Icon(
                Icons.check_circle,
                size: ComponentSizeTokens.iconSmall,
                color: widget.colors.successIcon,
              )
            else if (widget.onRemove != null)
              _DeleteButton(colors: widget.colors, onTap: widget.onRemove!),
          ],
        ),
      ),
    );
  }
}

/// 삭제 버튼 위젯
class _DeleteButton extends StatefulWidget {
  final FileUploadColors colors;
  final VoidCallback onTap;

  const _DeleteButton({required this.colors, required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colors.deleteButtonHover.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
          ),
          child: Icon(
            Icons.close,
            size: ComponentSizeTokens.iconSmall,
            color: _isHovered
                ? widget.colors.deleteButtonHover
                : widget.colors.deleteButton,
          ),
        ),
      ),
    );
  }
}
