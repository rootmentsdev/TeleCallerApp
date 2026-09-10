import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/chat_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/chat_screen/chat_conversation_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _channels = ['All', 'Instagram', 'Facebook', 'Whatsapp'];
  
  // Dummy values for brand pills, can be dynamic
  final List<String> _brands = ['All Chats', 'Suitor Guy', 'Zorucci', 'Dappr Squad'];
  String _selectedBrand = 'All Chats';
  
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _channels.length, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchFilteredData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFilteredData();
      
      // Poll inbox every 5 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          _fetchFilteredData(showLoading: false);
        }
      });
    });
  }

  void _fetchFilteredData({bool showLoading = true}) {
    final controller = Provider.of<ChatController>(context, listen: false);
    String channelParam = _channels[_tabController.index].toLowerCase();
    String brandParam = _selectedBrand == 'All Chats' ? '' : _selectedBrand;
    
    controller.fetchConversations(
      channel: channelParam,
      brand: brandParam,
      showLoading: showLoading,
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ChatController>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildTabBar(controller),
          const SizedBox(height: 16),
          _buildBrandPills(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildConversationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ChatController controller) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        padding: const EdgeInsets.only(right: 16),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
        indicatorWeight: 2,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: [
          _buildTab('All', controller.unreadCounts['all'] ?? 0),
          _buildTab('Instagram', controller.unreadCounts['instagram'] ?? 0),
          _buildTab('Facebook', controller.unreadCounts['facebook'] ?? 0),
          _buildTab('Whatsapp', controller.unreadCounts['whatsapp'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBrandPills() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _brands.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final brand = _brands[index];
          final isSelected = _selectedBrand == brand;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedBrand = brand;
              });
              _fetchFilteredData();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? ColorConstant.primaryColor : Colors.white,
                border: Border.all(
                  color: isSelected ? ColorConstant.primaryColor : const Color(0xFFE0E0E0),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  brand,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationList() {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        if (controller.isLoadingConversations) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.conversationsError != null) {
          return Center(child: Text(controller.conversationsError!));
        }

        if (controller.conversations.isEmpty) {
          return const Center(child: Text('No chats found.'));
        }

        return ListView.separated(
          itemCount: controller.conversations.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
          itemBuilder: (context, index) {
            final chat = controller.conversations[index];
            final participant = chat['participant'] ?? {};
            final lastMessage = chat['lastMessage'] ?? {};
            
            String title = participant['name'] ?? participant['phone'] ?? 'Unknown';
            String subtitle = lastMessage['text'] ?? 'Attachment';
            int unreadCount = int.tryParse(chat['unreadCount']?.toString() ?? '0') ?? 0;
            
            String channel = (chat['channel'] ?? '').toLowerCase();
            if (title.contains('(WhatsApp)')) {
              channel = 'whatsapp';
              title = title.replaceAll('(WhatsApp)', '').trim();
            } else if (title.contains('(Instagram)')) {
              channel = 'instagram';
              title = title.replaceAll('(Instagram)', '').trim();
            } else if (title.contains('(Facebook)')) {
              channel = 'facebook';
              title = title.replaceAll('(Facebook)', '').trim();
            }
            
            String timeText = '';
            if (lastMessage['timestamp'] != null) {
              try {
                DateTime parsedTime = DateTime.parse(lastMessage['timestamp'].toString()).toLocal();
                timeText = DateFormat('hh:mm a').format(parsedTime);
              } catch (e) {
                timeText = '';
              }
            }

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatConversationScreen(
                      conversationId: chat['_id'] ?? '',
                      participantName: title,
                      participantPhone: participant['phone'] ?? '',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF0F4F8),
                          child: Text(
                            title.isNotEmpty ? title[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: ColorConstant.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (channel == 'whatsapp' || channel == 'instagram' || channel == 'facebook')
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: channel == 'whatsapp' ? Colors.green : 
                                       channel == 'facebook' ? Colors.blue : null,
                                gradient: channel == 'instagram' ? const LinearGradient(
                                  colors: [
                                    Color(0xFFF58529),
                                    Color(0xFFDD2A7B),
                                    Color(0xFF8134AF),
                                  ],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ) : null,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: FaIcon(
                                channel == 'whatsapp' ? FontAwesomeIcons.whatsapp : 
                                channel == 'instagram' ? FontAwesomeIcons.instagram : 
                                FontAwesomeIcons.facebookF,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unreadCount > 0 ? ColorConstant.primaryColor : Colors.grey[500],
                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                                    fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.green, // Vibrant green for unread
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
