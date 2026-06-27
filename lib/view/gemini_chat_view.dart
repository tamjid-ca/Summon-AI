import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:summon_ai/model/chat_model.dart';
import 'package:summon_ai/view_model/chat_view_model.dart';

class GeminiChatPanel extends StatefulWidget {
  const GeminiChatPanel({
    super.key,
    required this.viewModel,
    required this.onClose,
  });

  final ChatViewModel viewModel;
  final VoidCallback onClose;

  @override
  State<GeminiChatPanel> createState() => _GeminiChatPanelState();
}

class _GeminiChatPanelState extends State<GeminiChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  PendingChatImage? _pendingImage;
  String? _localError;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _localError = null);
    final file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (file == null) return;
    await _loadImage(file);
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    setState(() {
      _isDragging = false;
      _localError = null;
    });
    XFile? image;
    for (final file in files) {
      if (_isImageFile(file)) {
        image = file;
        break;
      }
    }
    if (image == null) {
      setState(() => _localError = 'Drop an image file only.');
      return;
    }
    await _loadImage(image);
  }

  Future<void> _loadImage(XFile file) async {
    final size = await file.length();
    if (size > ChatViewModel.maxImageBytes) {
      setState(() {
        _pendingImage = null;
        _localError = 'Image must be 2 MB or smaller.';
      });
      return;
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _pendingImage = PendingChatImage(
        fileName: file.name,
        mimeType: file.mimeType ?? _mimeTypeFromName(file.name),
        sizeBytes: size,
        bytes: bytes,
      );
    });
  }

  bool _isImageFile(XFile file) {
    final mimeType = file.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return true;
    final lower = file.name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    final image = _pendingImage;
    _controller.clear();
    setState(() {
      _pendingImage = null;
      _localError = null;
    });
    await widget.viewModel.sendMessage(text, image);
    if (widget.viewModel.errorMessage != null) {
      setState(() {
        _localError = widget.viewModel.errorMessage;
        if (widget.viewModel.errorMessage!.startsWith('Chat failed:')) {
          _controller.text = text;
          _pendingImage = image;
        }
      });
    }
  }

  String _mimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 760;
    return DropTarget(
      onDragDone: (detail) => _handleDroppedFiles(detail.files),
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        body: SafeArea(
          child: Center(
            child: Container(
              width: isWide ? 920 : double.infinity,
              height: isWide ? 680 : double.infinity,
              margin: EdgeInsets.all(isWide ? 24 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1020),
                borderRadius: BorderRadius.circular(isWide ? 18 : 0),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 34,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedBuilder(
                animation: widget.viewModel,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Row(
                        children: [
                          if (isWide)
                            _SessionSidebar(viewModel: widget.viewModel),
                          Expanded(
                            child: Column(
                              children: [
                                _ChatHeader(
                                  showMenu: !isWide,
                                  onMenu: () => _openSessionsSheet(context),
                                  onClose: widget.onClose,
                                ),
                                Expanded(child: _MessageList(widget.viewModel)),
                                if (_localError != null ||
                                    widget.viewModel.errorMessage != null)
                                  _ErrorBanner(
                                    message: _localError ??
                                        widget.viewModel.errorMessage ??
                                        '',
                                  ),
                                _ChatComposer(
                                  controller: _controller,
                                  pendingImage: _pendingImage,
                                  isSending: widget.viewModel.isSending,
                                  focusNode: _inputFocusNode,
                                  onRemoveImage: () {
                                    setState(() => _pendingImage = null);
                                  },
                                  onPickImage: () {
                                    _pickImage(ImageSource.gallery);
                                  },
                                  onCamera: () => _pickImage(ImageSource.camera),
                                  onSend: _send,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isDragging)
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFF4776E6)
                                .withValues(alpha: 0.18),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1020),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF7EAEFF),
                                  ),
                                ),
                                child: const Text(
                                  'Drop image to attach',
                                  style: TextStyle(
                                    color: Color(0xFF7EAEFF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSessionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111226),
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: _SessionSidebar(viewModel: widget.viewModel),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.showMenu,
    required this.onMenu,
    required this.onClose,
  });

  final bool showMenu;
  final VoidCallback onMenu;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14162B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Chat history',
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gemini Chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close chat',
          ),
        ],
      ),
    );
  }
}

class _SessionSidebar extends StatelessWidget {
  const _SessionSidebar({required this.viewModel});

  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF111226),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: FilledButton.icon(
              onPressed: viewModel.createNewChat,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New chat'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
          Expanded(
            child: viewModel.isLoadingSessions
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    itemCount: viewModel.sessions.length,
                    itemBuilder: (context, index) {
                      final session = viewModel.sessions[index];
                      final selected = session.id == viewModel.selectedSessionId;
                      return _SessionTile(
                        session: session,
                        selected: selected,
                        onTap: () {
                          viewModel.selectSession(session.id);
                          Navigator.maybePop(context);
                        },
                        onRename: () => _rename(context, session),
                        onDelete: () => _delete(context, session),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, ChatSession session) async {
    final controller = TextEditingController(text: session.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename chat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Chat title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (title != null) {
      await viewModel.renameSession(session.id, title);
    }
  }

  Future<void> _delete(BuildContext context, ChatSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete chat?'),
          content: Text('This removes "${session.title}" and its messages.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await viewModel.deleteSession(session.id);
    }
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final ChatSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF20254A) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? const Color(0xFF4776E6).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        title: Text(
          session.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 18),
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList(this.viewModel);

  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.selectedSessionId == null && viewModel.sessions.isEmpty) {
      return const _EmptyChat();
    }
    if (viewModel.messages.isEmpty && !viewModel.isSending) {
      return const _EmptyChat();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: viewModel.messages.length + (viewModel.isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= viewModel.messages.length) {
          return const _TypingBubble();
        }
        return _MessageBubble(
          message: viewModel.messages[index],
          viewModel: viewModel,
        );
      },
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF4776E6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF7EAEFF),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start a Gemini conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask a question, upload an image, or take a photo for Gemini to analyze.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.viewModel,
  });

  final ChatMessage message;
  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF26346B) : const Color(0xFF181A31),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachment != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _StoredBase64Image(
                  message: message,
                  viewModel: viewModel,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (message.text.trim().isNotEmpty)
              SelectableText(
                message.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoredBase64Image extends StatelessWidget {
  const _StoredBase64Image({
    required this.message,
    required this.viewModel,
  });

  final ChatMessage message;
  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: viewModel.imageBytesFor(message),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            width: 240,
            height: 150,
            alignment: Alignment.center,
            color: Colors.black.withValues(alpha: 0.18),
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty || snapshot.hasError) {
          return Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            color: Colors.black.withValues(alpha: 0.18),
            child: const Text('Image could not be loaded from Firestore.'),
          );
        }
        return Image.memory(
          bytes,
          width: 240,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF181A31),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Gemini is thinking...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B8A)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFFB3C2)),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.pendingImage,
    required this.isSending,
    required this.focusNode,
    required this.onRemoveImage,
    required this.onPickImage,
    required this.onCamera,
    required this.onSend,
  });

  final TextEditingController controller;
  final PendingChatImage? pendingImage;
  final bool isSending;
  final FocusNode focusNode;
  final VoidCallback onRemoveImage;
  final VoidCallback onPickImage;
  final VoidCallback onCamera;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF14162B),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          if (pendingImage != null) _PendingImagePreview(
            image: pendingImage!,
            onRemove: onRemoveImage,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: isSending ? null : onPickImage,
                icon: const Icon(Icons.attach_file_rounded),
                tooltip: 'Upload image',
              ),
              IconButton(
                onPressed: isSending ? null : onCamera,
                icon: const Icon(Icons.photo_camera_rounded),
                tooltip: 'Take photo',
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onTap: focusNode.requestFocus,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !isSending,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Message Gemini...',
                    filled: true,
                    fillColor: const Color(0xFF0F1020),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isSending ? null : onSend,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingImagePreview extends StatelessWidget {
  const _PendingImagePreview({
    required this.image,
    required this.onRemove,
  });

  final PendingChatImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(image.bytes),
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${image.fileName} (${(image.sizeBytes / 1024).toStringAsFixed(0)} KB)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Remove image',
          ),
        ],
      ),
    );
  }
}
