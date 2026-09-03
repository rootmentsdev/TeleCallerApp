import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/chat_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/chat_screen/widgets/convert_lead_bottom_sheet.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String participantName;
  final String participantPhone;

  const ChatConversationScreen({
    Key? key,
    required this.conversationId,
    required this.participantName,
    required this.participantPhone,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ChatController>(context, listen: false);
      controller.fetchMessages(widget.conversationId);
      controller.markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final controller = Provider.of<ChatController>(context, listen: false);
      controller.sendMessage(widget.conversationId, text);
      _messageController.clear();
      // Since it's optimistic or needs reload:
      controller.fetchMessages(widget.conversationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.chatBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
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
              }
            },
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: 'transfer',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Text('Transfer'),
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
                  reverse: true, // Show newest at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Reverse index to display correctly
                    final message = messages[messages.length - 1 - index];
                    final isOutbound = message['senderType'] == 'telecaller';
                    
                    return _buildMessageBubble(
                      message['text'] ?? '',
                      '11:18 AM', // TODO: format timestamp
                      isOutbound,
                    );
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

  Widget _buildMessageBubble(String text, String time, bool isOutbound) {
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
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }

  void _showQuickReplies() {
    final List<Map<String, String>> quickReplies = [
      {'title': 'Store Location', 'text': 'Our showroom is located in Edappally, Kochi. We are open from 10 AM to 8 PM.'},
      {'title': 'Greeting', 'text': 'Hello! Thank you for reaching out to us. How can I assist you today?'},
      {'title': 'Fitting Confirmation', 'text': 'Can we schedule a quick fitting session for you this weekend?'},
      {'title': 'Pricing Range', 'text': 'Our premium suits start at ₹4,999. Do you have a specific style in mind?'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Quick Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ...quickReplies.map((reply) => ListTile(
              title: Text(reply['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(reply['text']!, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                _messageController.text = reply['text']!;
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: ColorConstant.chatBubbleBlue.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _showQuickReplies,
                    child: const Icon(Icons.bolt, color: Colors.amber, size: 26),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type something...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const Icon(Icons.mic_none, color: Colors.black54, size: 22),
                  const SizedBox(width: 8),
                  const Icon(Icons.camera_alt_outlined, color: Colors.black54, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstant.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
