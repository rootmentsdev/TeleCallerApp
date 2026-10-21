import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/chat_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:telecaller_app/view/chat_screen/widgets/convert_lead_bottom_sheet.dart';
import 'package:telecaller_app/view/chat_screen/widgets/audio_player_widget.dart';
import 'package:telecaller_app/view/chat_screen/widgets/media_view_screen.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:telecaller_app/view/chat_screen/widgets/send_brochure_bottom_sheet.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String participantName;
  final String participantPhone;
  final String? channel;
  final String? brand;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.participantPhone,
    this.channel,
    this.brand,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  // Recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ChatController>(context, listen: false);
      controller.fetchMessages(widget.conversationId);
      controller.markAsRead(widget.conversationId);
      
      // Start polling for new incoming messages every 3 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          controller.fetchMessages(widget.conversationId, showLoading: false);
        }
      });
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final dir = await getTemporaryDirectory();
        _audioPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _audioPath!,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      if (!cancel && path != null) {
        // Send audio message
        final controller = Provider.of<ChatController>(context, listen: false);
        controller.sendMediaMessage(widget.conversationId, path, 'audio');
        _scrollToBottom();
      }
    } catch (e) {
      print('Error stopping record: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _showCameraOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    final controller = Provider.of<ChatController>(this.context, listen: false);
                    controller.sendMediaMessage(widget.conversationId, picked.path, 'image');
                    _scrollToBottom();
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.photo, color: Colors.white),
                ),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickMedia();
                  if (picked != null) {
                    final isVideo = picked.path.endsWith('.mp4') || picked.path.endsWith('.mov');
                    final controller = Provider.of<ChatController>(this.context, listen: false);
                    controller.sendMediaMessage(widget.conversationId, picked.path, isVideo ? 'video' : 'image');
                    _scrollToBottom();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    final controller = Provider.of<ChatController>(this.context, listen: false);
                    controller.sendMediaMessage(widget.conversationId, picked.path, 'image');
                    _scrollToBottom();
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: Icon(Icons.photo, color: Colors.white),
                ),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickMedia();
                  if (picked != null) {
                    final isVideo = picked.path.endsWith('.mp4') || picked.path.endsWith('.mov');
                    final controller = Provider.of<ChatController>(this.context, listen: false);
                    controller.sendMediaMessage(widget.conversationId, picked.path, isVideo ? 'video' : 'image');
                    _scrollToBottom();
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.insert_drive_file, color: Colors.white),
                ),
                title: const Text('Document'),
                onTap: () async {
                  Navigator.pop(context);
                  FilePickerResult? result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final controller = Provider.of<ChatController>(this.context, listen: false);
                    controller.sendMediaMessage(widget.conversationId, result.files.single.path!, 'document');
                    _scrollToBottom();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final controller = Provider.of<ChatController>(context, listen: false);
      controller.sendMessage(widget.conversationId, text);
      _messageController.clear();
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  bool _isWhatsAppConversation(ChatController chatController) {
    if (widget.channel != null &&
        widget.channel!.toLowerCase().trim() == 'whatsapp') {
      return true;
    }
    final convIndex = chatController.conversations
        .indexWhere((c) => c['_id'] == widget.conversationId);
    if (convIndex != -1) {
      final conv = chatController.conversations[convIndex];
      final ch = (conv['channel'] ?? '').toString().toLowerCase().trim();
      if (ch == 'whatsapp') return true;
      final pName =
          (conv['participant']?['name'] ?? '').toString().toLowerCase();
      if (pName.contains('(whatsapp)')) return true;
    }
    if (widget.participantName.toLowerCase().contains('(whatsapp)')) {
      return true;
    }
    return false;
  }

  void _openSendBrochureSheet(String brand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendBrochureBottomSheet(
        conversationId: widget.conversationId,
        participantName: widget.participantName,
        participantPhone: widget.participantPhone,
        initialBrand: brand,
        onSuccess: () {
          final controller =
              Provider.of<ChatController>(context, listen: false);
          controller.fetchMessages(widget.conversationId, showLoading: false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);
    final convIndex = chatController.conversations.indexWhere((c) => c['_id'] == widget.conversationId);
    final brand = convIndex != -1 
        ? (chatController.conversations[convIndex]['brand']?.toString().toLowerCase() ?? widget.brand?.toLowerCase() ?? 'zorucci') 
        : (widget.brand?.toLowerCase() ?? 'zorucci');
    final isWhatsApp = _isWhatsAppConversation(chatController);

    String brandInitial = 'Z';
    Color avatarColor = Colors.pinkAccent; 
    if (brand == 'suitor_guy' || brand == 'suitor guy') {
      brandInitial = 'SG';
      avatarColor = Colors.blueAccent;
    } else if (brand == 'dapper_squad' || brand == 'dappersquad') {
      brandInitial = 'DS';
      avatarColor = Colors.green;
    }

    return Scaffold(
      backgroundColor: ColorConstant.chatBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 100,
        leading: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 16,
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Text(
                brandInitial,
                style: TextStyle(
                  color: avatarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        title: Column(
          children: [
            Text(
              widget.participantName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
            if (widget.participantPhone.isNotEmpty)
              Text(
                widget.participantPhone,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (isWhatsApp)
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Color(0xFF25D366),
                size: 22,
              ),
              tooltip: 'Send WhatsApp Brochure',
              onPressed: () => _openSendBrochureSheet(brand),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'convert_lead') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ConvertLeadBottomSheet(
                    conversationId: widget.conversationId,
                    participantName: widget.participantName,
                    participantPhone: widget.participantPhone,
                  ),
                );
              } else if (value == 'send_brochure') {
                _openSendBrochureSheet(brand);
              }
            },
            itemBuilder: (context) => [
              if (isWhatsApp)
                const PopupMenuItem(
                  value: 'send_brochure',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18),
                      SizedBox(width: 8),
                      Text('Send Brochure Template'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'convert_lead',
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('Convert to Lead'),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatController>(
              builder: (context, controller, _) {
                if (controller.isLoadingMessages && controller.currentMessages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.messagesError != null && controller.currentMessages.isEmpty) {
                  return Center(child: Text(controller.messagesError!));
                }

                final messages = controller.currentMessages;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final int i = messages.length - 1 - index;
                    final message = messages[i];
                    final isOutbound = message['senderType'] == 'telecaller';
                    
                    DateTime? currentMsgTime;
                    if (message['timestamp'] != null) {
                      try {
                        currentMsgTime = DateTime.parse(message['timestamp'].toString()).toLocal();
                      } catch (_) {}
                    }

                    bool showDateHeader = false;
                    if (currentMsgTime != null) {
                      if (i == 0) {
                        showDateHeader = true;
                      } else {
                        final prevMessage = messages[i - 1];
                        DateTime? prevMsgTime;
                        if (prevMessage['timestamp'] != null) {
                          try {
                            prevMsgTime = DateTime.parse(prevMessage['timestamp'].toString()).toLocal();
                          } catch (_) {}
                        }
                        if (prevMsgTime == null ||
                            currentMsgTime.year != prevMsgTime.year ||
                            currentMsgTime.month != prevMsgTime.month ||
                            currentMsgTime.day != prevMsgTime.day) {
                          showDateHeader = true;
                        }
                      }
                    }

                    String timeText = '';
                    if (currentMsgTime != null) {
                      timeText = DateFormat('hh:mm a').format(currentMsgTime);
                    }

                    final messageBubble = _buildMessageBubble(
                      message,
                      timeText,
                      isOutbound,
                      status: message['status'] ?? 'sent',
                    );

                    if (showDateHeader && currentMsgTime != null) {
                      return Column(
                        children: [
                          _buildDateHeader(currentMsgTime),
                          messageBubble,
                        ],
                      );
                    }
                    
                    return messageBubble;
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status, String? tempId) {
    final primaryColor = ColorConstant.primaryColor;
    
    switch (status) {
      case 'sending':
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 4, bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.8), width: 1.5),
            color: Colors.transparent, // Hollow circle
          ),
        );
      case 'sent':
      case 'delivered':
      case 'read':
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 4, bottom: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor, // Solid filled primary color bullet
          ),
        );
      case 'failed':
        return GestureDetector(
          onTap: () {
            if (tempId != null) {
              final controller = Provider.of<ChatController>(context, listen: false);
              controller.retryMessage(tempId);
            }
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 4.0),
            child: Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReelPreview({String? url, String? title, String? thumbnailUrl, required bool isReel}) {
    return GestureDetector(
      onTap: () async {
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: isReel ? 9 / 16 : 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                ),
              )
            else
              Container(
                height: 120,
                color: Colors.grey[300],
                child: Center(
                  child: Icon(
                    isReel ? Icons.video_collection : Icons.link,
                    size: 40,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isReel ? Icons.smart_display : Icons.share,
                    size: 16,
                    color: isReel ? Colors.pinkAccent : Colors.blueAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title != null && title.isNotEmpty ? title : (isReel ? 'Instagram Reel' : 'Shared Link'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithLinks(String text) {
    final urlRegExp = RegExp(
        r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
        caseSensitive: false);
    final matches = urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.3),
      );
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.3),
        ));
      }

      String url = match.group(0)!;
      final uriStr = url.startsWith('http') ? url : 'https://$url';

      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 15,
          height: 1.3,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()..onTap = () async {
          final uri = Uri.parse(uriStr);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.3),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildMessageBubble(Map message, String time, bool isOutbound, {String status = 'sent'}) {
    final String text = message['text'] ?? '';
    final String tempId = message['tempId']?.toString() ?? '';
    final String messageType = message['messageType'] ?? 'text';
    final Map? mediaMap = message['media'] is Map ? message['media'] : null;
    final String? rawAttachmentUrl = message['attachmentUrl'] ?? mediaMap?['url'];
    final String? fileId = mediaMap?['fileId']?.toString() ?? message['fileId']?.toString();
    final String? attachmentUrl = rawAttachmentUrl != null ? ApiConfig.resolveMediaUrl(rawAttachmentUrl, fileId) : (fileId != null ? ApiConfig.resolveMediaUrl(null, fileId) : null);
    final String? localFilePath = message['localFilePath'];
    final String? title = message['title'] ?? message['caption'] ?? mediaMap?['title'] ?? mediaMap?['caption'];
    final String? rawThumbnailUrl = message['thumbnailUrl'] ?? mediaMap?['thumbnailUrl'];
    final String? thumbnailUrl = rawThumbnailUrl != null ? ApiConfig.resolveMediaUrl(rawThumbnailUrl, null) : null;
    
    Widget contentWidget;
    
    if (messageType == 'audio') {
      contentWidget = AudioPlayerWidget(
        audioUrl: localFilePath ?? attachmentUrl ?? '',
        isLocal: localFilePath != null,
        isOutbound: isOutbound,
      );
    } else if (messageType == 'image') {
      contentWidget = GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MediaViewScreen(
            type: 'image',
            url: attachmentUrl,
            localPath: localFilePath,
          )));
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          clipBehavior: Clip.hardEdge,
          child: localFilePath != null
              ? Image.file(File(localFilePath), fit: BoxFit.cover)
              : (attachmentUrl != null ? CachedNetworkImage(imageUrl: attachmentUrl, fit: BoxFit.cover) : const Icon(Icons.broken_image)),
        ),
      );
    } else if (messageType == 'video') {
      contentWidget = GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MediaViewScreen(
            type: 'video',
            url: attachmentUrl,
            localPath: localFilePath,
          )));
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          child: const Center(
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: Icon(Icons.play_arrow, color: Colors.white),
            ),
          ),
        ),
      );
    } else if (messageType == 'document') {
      contentWidget = GestureDetector(
        onTap: () async {
          if (localFilePath != null) {
            await OpenFilex.open(localFilePath);
          } else if (attachmentUrl != null) {
            try {
              // Show a loading snackbar (optional)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading document...')));
              final response = await http.get(Uri.parse(attachmentUrl));
              if (response.statusCode == 200) {
                final tempDir = await getTemporaryDirectory();
                final fileName = message['media']?['fileName'] ?? 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
                final file = File('${tempDir.path}/$fileName');
                await file.writeAsBytes(response.bodyBytes);
                await OpenFilex.open(file.path);
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download document')));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error downloading document')));
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, size: 30, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message['media']?['fileName'] ?? 'Document',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (messageType == 'ig_reel' || messageType == 'share') {
      contentWidget = _buildReelPreview(
        url: attachmentUrl,
        title: title ?? text,
        thumbnailUrl: thumbnailUrl,
        isReel: messageType == 'ig_reel',
      );
    } else if (messageType == 'text') {
      contentWidget = _buildTextWithLinks(text);
    } else {
      // Fallback for unknown types
      contentWidget = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Text('Unsupported message', style: TextStyle(color: Colors.orange)),
          ],
        ),
      );
    }

    return Align(
      alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOutbound ? ColorConstant.chatBubbleBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOutbound ? 16 : 4),
            bottomRight: Radius.circular(isOutbound ? 4 : 16),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          alignment: WrapAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                contentWidget,
                if (text.isNotEmpty && messageType != 'text') ...[
                  const SizedBox(height: 8),
                  _buildTextWithLinks(text),
                ],
              ],
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ),
                if (isOutbound) _buildStatusIndicator(status, tempId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickReplies() {
    final chatController = Provider.of<ChatController>(context, listen: false);
    final convIndex = chatController.conversations.indexWhere((c) => c['_id'] == widget.conversationId);
    final brand = convIndex != -1 ? (chatController.conversations[convIndex]['brand']?.toString().toLowerCase() ?? 'zorucci') : 'zorucci';

    final feedbackMsg = {'title': 'Feedback - Grooms Wedding Hub', 'text': 'FEEDBACK ------ Hi sir This is from Grooms Wedding Hub. We had tried to contact you regarding your recent rental experience .\n\nWere you satisfied with the product and our service? Also, was your security deposit refunded successfully? If you have any suggestions or feedback, we\'d be happy to hear them.'};

    List<Map<String, String>> quickReplies = [];

    if (brand == 'suitor_guy' || brand == 'suitor guy') {
      quickReplies = [
        feedbackMsg,
        {'title': 'Welcome - Suitor Guy', 'text': 'Hello sir! Thank you for reaching out to Suitor Guy! For further assistance, kindly share your name and whatsapp number. Our person will contact you and help you with all details.'},
        {'title': 'Location Request', 'text': 'Could you please share your location? I can connect you with the nearest store for details on availability, styles, and pricing. 😊'},
        {'title': 'Address - Trivandrum', 'text': '📍 *TRIVANDRUM*\nAddress: CTO Colony, Pappanamcode Signal, above Pizza Hut, TVM\nMob: 7593838700\nLocation: https://maps.google.com/?cid=8319081956517837607'},
        {'title': 'Address - Kottayam', 'text': '📍 *KOTTAYAM*\nAddress: Nedumgattu Chambers, Chavittuvary, S.H. Mount P.O., Kumaranalloor, Kottayam\nMob: 7593838701\nLocation: https://maps.google.com/?cid=9913747055090203530'},
        {'title': 'Address - Edappally', 'text': '📍 *EDAPPALLY*\nAddress: Valiyara Building, near Edappally flyover, metro pillar no. 411, Edappally\nMob: 7593838702\nLocation: https://maps.google.com/?cid=1161245051819694225'},
        {'title': 'Address - Perumbavoor', 'text': '📍 *PERUMBAVOOR*\nAddress: Oushady Junction, SH 1, Perumbavoor\nMob: 7593838703\nLocation: https://maps.google.com/?cid=7002759938181771403'},
        {'title': 'Address - MG Road (Kochi)', 'text': '📍 *MG ROAD (KOCHI)*\nAddress: Pillar number 666, above Purple store, Padma Jn, MG Road\nMob: 7593838718\nLocation: https://maps.google.com/?cid=2846341348885852423'},
        {'title': 'Address - Thrissur', 'text': '📍 *THRISSUR*\nAddress: Thrissur Kunnamkulam Road, near Akshaya hotel, opposite Jawa, Puzhakkal, Punkunnam\nMob: 7593838704\nLocation: https://maps.google.com/?cid=1082858929553487267'},
        {'title': 'Address - Palakkad', 'text': '📍 *PALAKKAD*\nAddress: P&G tower, Stadium Bypass Rd, Sultanpet, OPP MYG, Palakkad\nMob: 7593838705\nLocation: https://maps.google.com/?cid=1067793962218177022'},
        {'title': 'Address - Chavakkad', 'text': '📍 *CHAVAKKAD*\nAddress: SH50, Ovungal, Friend Ship Nagar, Chavakkad\nMob: 7593838706\nLocation: https://maps.google.com/?cid=381099851137187847'},
        {'title': 'Address - Edappal', 'text': '📍 *EDAPPAL*\nAddress: Edappal - Kuttippuram Rd, Edappal\nMob: 7593838707\nLocation: https://maps.google.com/?cid=9652609964433236977'},
        {'title': 'Address - Kottakkal', 'text': '📍 *KOTTAKKAL*\nAddress: Kottakkal, Changuvetty\nMob: 7593838711\nLocation: https://maps.google.com/?cid=11648552372167711397'},
        {'title': 'Address - Manjeri', 'text': '📍 *MANJERI*\nAddress: Thurakkal, Baputty bypass, above Jockey store, Manjeri\nMob: 7593838710\nLocation: https://maps.google.com/?cid=18043496880213144185'},
        {'title': 'Address - Perinthalmanna', 'text': '📍 *PERINTHALMANNA*\nAddress: Nagapattinam - Coimbatore - Gundlupet Hwy, Valiyangadi, Perinthalmanna\nMob: 7593838709\nLocation: https://maps.google.com/?cid=12993779800238452778'},
        {'title': 'Address - Calicut', 'text': '📍 *CALICUT*\nAddress: Bypass road, opp IT PARK, service road, near HiLITE Mall\nMob: 7593838712\nLocation: https://maps.google.com/?cid=17886891594058553114'},
        {'title': 'Address - Vadakara', 'text': '📍 *VADAKARA*\nAddress: JH2V+834, Nut Street, Vadakara\nMob: 7593838708\nLocation: https://maps.google.com/?cid=3698317130838058217'},
        {'title': 'Address - Kannur', 'text': '📍 *KANNUR*\nAddress: Melechowa South, near water tank, Kannur\nMob: 7593838716\nLocation: https://maps.google.com/?cid=3261466748685059937'},
        {'title': 'Address - Kalpetta (Wayanad)', 'text': '📍 *KALPETTA (WAYANAD)*\nAddress: J3JQ+4JW, Civil Station, Madathumpadi, Kalpetta, Kainatty\nMob: 7593838717\nLocation: https://maps.google.com/?cid=518906568570003149'},
      ];
    } else {
      quickReplies = [
        {'title': 'Welcome - Zorucci', 'text': 'Hello mam! Thank you for reaching out to Zoruccci, your premium bridal rental destination! For further assistance, kindly share your name and whatsapp number. Our person will contact you and help you with all details.'},
        {'title': 'Nearest Store Inquiry', 'text': 'Our store available in Edappally (Eranakulam) Edappal,Kottakkal,Perinthalmanna (malappuram) Which store is nearest you?'},
        {'title': 'Address - Edappally', 'text': '📍 Zorucci Premium Rental ,Edappally Address: Metro Piller No 366, Chilton Tower, Road, Koonamthai, Edappally, Aluva, Kochi, Kerala 682024 Mob: 6235031144 Location : https://maps.app.goo.gl/6f8usJeSzLDba3Nh8?g_st=awb'},
        {'title': 'Call Assistance', 'text': 'Mam, I will be able to give you a prompt and detailed assistance over a call, Could you please give me your contact details?'},
        {'title': 'Location Request', 'text': 'Could you please share your location? I can connect you with the nearest store for details on availability, styles, and pricing. 😊'},
        {'title': 'Contact for Pricing', 'text': 'For more details,Pricing and availability Kindly contact this number 🙂'},
        {'title': 'Call Assistance (Repeat)', 'text': 'Mam, I will be able to give you a prompt and detailed assistance over a call, Could you please give me your contact details?'},
        {'title': 'Address - Perinthalmanna', 'text': '📍 Zorucci Premium Rental, Perinthalmanna Address: Sahara Complex, Mysuru - Ooty Rd, Valiyangadi, Perinthalmanna, Kerala 679322 Phone: 6235031133 Location : https://maps.app.goo.gl/Kuoi2ZGdsN7mvyxL6?g_st=awb'},
        {'title': 'Location - Perinthalmanna', 'text': '📍 Location : https://maps.app.goo.gl/Kuoi2ZGdsN7mvyxL6?g_st=awb'},
        {'title': 'Address - Perinthalmanna (Details)', 'text': '📍 Zorucci Premium Rental, Perinthalmanna\nAddress: Sahara Complex, Mysuru - Ooty Rd, Valiyangadi, Perinthalmanna, Kerala 679322\nPhone: 6235031133'},
        {'title': 'Address - Kottakkal', 'text': '📍 Zorucci Bridal Wedding Hub Premium Rentals, Kottakkal Address: Zabeel complex Changuvetty, Kottakkal, Kerala 676503 Phone: 6235031122 Location : https://maps.app.goo.gl/MHBKuUA4Nv2jZ7Ak9?g_st=awb'},
        {'title': 'Support Check', 'text': 'Hi mam, Did you get the support from the team?'},
        {'title': 'No Outfits Accepted', 'text': 'Dear , Zorucci exclusively offer premium quality in house manufactured designs to ensure our clients receive the best experience. Unfortunately, we do not accept outfits mam.'},
        {'title': 'Query Forward', 'text': 'Hi, Thank you for reaching out to Zoruccci, your premier bridal rental destination! I will forward your query to the concerned person.'},
        {'title': 'Address - Edappal', 'text': '📍 Zorucci Premium Rentals Edappal Address: Calicut Rd, Edappal, Kerala 679576 Phone: 6235031100 Location : https://maps.app.goo.gl/1j9EVVbE3znzQRvT6?g_st=awb'},
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Quick Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: quickReplies.length,
                  itemBuilder: (context, index) {
                    final reply = quickReplies[index];
                    return ListTile(
                      title: Text(reply['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(reply['text']!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        _messageController.text = reply['text']!;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: _isRecording
                ? _buildRecordingBar()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ColorConstant.chatBubbleBlue.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _showQuickReplies,
                          child: const Icon(Icons.bolt,
                              color: Colors.amber, size: 26),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type something...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        InkWell(
                          onTap: _pickAttachment,
                          child: const Icon(Icons.attach_file,
                              color: Colors.black54, size: 22),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showCameraOptions,
                          child: const Icon(Icons.camera_alt_outlined,
                              color: Colors.black54, size: 22),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.redAccent
                    : ColorConstant.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _messageController.text.isNotEmpty
                    ? Icons.send
                    : Icons.mic,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    final minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDuration % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 8),
          Text('$minutes:$seconds', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Text('Release to send', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
