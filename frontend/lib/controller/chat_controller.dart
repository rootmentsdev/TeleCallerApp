import 'package:flutter/material.dart';
import 'package:telecaller_app/services/http_client.dart';
import 'package:telecaller_app/utils/api_config.dart';
import 'package:telecaller_app/services/auth_service.dart';
// Note: You will need to uncomment or implement ChatSocketService according to your architecture later
// import 'package:telecaller_app/services/chat_socket_service.dart';

class ChatController extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  // final ChatSocketService _socketService = ChatSocketService();

  // --- State Variables ---
  
  // Inbox state
  List<dynamic> _conversations = [];
  bool _isLoadingConversations = false;
  String? _conversationsError;

  // Active Conversation state
  List<dynamic> _currentMessages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;
  String? _activeConversationId;

  // Filters
  String? _selectedBrand;
  String? _selectedChannel;
  String _selectedStatus = 'open';

  // Unread counts per channel
  Map<String, int> _unreadCounts = {
    'all': 0,
    'instagram': 0,
    'facebook': 0,
    'whatsapp': 0,
  };

  // --- Getters ---
  
  List<dynamic> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get conversationsError => _conversationsError;

  List<dynamic> get currentMessages => _currentMessages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;

  String? get selectedBrand => _selectedBrand;
  String? get selectedChannel => _selectedChannel;
  String get selectedStatus => _selectedStatus;
  
  Map<String, int> get unreadCounts => _unreadCounts;

  String? get activeConversationId => _activeConversationId;

  // --- Methods ---

  /// Initialize WebSocket connection
  Future<void> initSocket() async {
    final token = await AuthService.getToken();
    if (token != null) {
      // _socketService.connect(ApiConfig.baseUrl, token);
      // _setupSocketListeners();
    }
  }

  void disconnectSocket() {
    // _socketService.disconnect();
  }

  /*
  void _setupSocketListeners() {
    _socketService.socket.on('chat:message', (data) {
      // Handle new incoming message
      // 1. If it belongs to _activeConversationId, add to _currentMessages
      // 2. Update the conversation preview in _conversations
      notifyListeners();
    });

    _socketService.socket.on('chat:status_update', (data) {
      // Update message read/delivered status
      notifyListeners();
    });
  }
  */

  /// Fetch Chat Inbox Conversations
  Future<void> fetchConversations({
    String? channel,
    String? brand,
    String status = 'open',
    bool showLoading = true,
  }) async {
    _selectedChannel = channel;
    _selectedBrand = brand;
    _selectedStatus = status;
    
    if (showLoading && _conversations.isEmpty) {
      _isLoadingConversations = true;
      notifyListeners();
    }
    _conversationsError = null;

    try {
      List<String> queryParams = [];
      if (channel != null && channel.isNotEmpty && channel.toLowerCase() != 'all') {
        queryParams.add("channel=${Uri.encodeComponent(channel)}");
      }
      if (brand != null && brand.isNotEmpty && brand.toLowerCase() != 'all brands') {
        queryParams.add("brand=${Uri.encodeComponent(brand)}");
      }
      queryParams.add("status=${Uri.encodeComponent(status)}");

      final String url = "${ApiConfig.chatEndpoint}/conversations?${queryParams.join('&')}";
      print("CHAT DEBUG: Fetching from $url");
      
      final response = await _httpClient.get(url);
      print("CHAT DEBUG: Response body: $response");
      
      if (response != null && response['data'] != null) {
        final data = response['data'];
        if (data is Map && data.containsKey('conversations')) {
          _conversations = data['conversations'] ?? [];
          if (data.containsKey('unreadCounts')) {
             // If backend provides the counts directly
             final counts = data['unreadCounts'];
             _unreadCounts = {
                'all': counts['all'] ?? 0,
                'instagram': counts['instagram'] ?? 0,
                'facebook': counts['facebook'] ?? 0,
                'whatsapp': counts['whatsapp'] ?? 0,
             };
          }
        } else if (data is List) {
          _conversations = data;
        } else {
          _conversations = [];
        }
        
        // Frontend logic to calculate counts if we fetch 'All'
        if ((channel == null || channel.toLowerCase() == 'all') && (brand == null || brand.isEmpty || brand.toLowerCase() == 'all chats')) {
          int wa = 0, ig = 0, fb = 0;
          for (var chat in _conversations) {
             int unread = int.tryParse(chat['unreadCount']?.toString() ?? '0') ?? 0;
             if (unread > 0) {
                 String ch = (chat['channel'] ?? '').toString().toLowerCase();
                 
                 if (ch.isEmpty) {
                    String title = (chat['participant']?['name'] ?? chat['participant']?['phone'] ?? '').toString().toLowerCase();
                    if (title.contains('(whatsapp)')) ch = 'whatsapp';
                    else if (title.contains('(instagram)')) ch = 'instagram';
                    else if (title.contains('(facebook)')) ch = 'facebook';
                 }
                 
                 if (ch == 'whatsapp') wa += 1;
                 else if (ch == 'instagram') ig += 1;
                 else if (ch == 'facebook') fb += 1;
             }
          }
          _unreadCounts = {
             'all': wa + ig + fb,
             'whatsapp': wa,
             'instagram': ig,
             'facebook': fb,
          };
        }
      } else if (response != null && response['success'] == true) {
         _conversations = response['data'] ?? [];
      } else {
        _conversationsError = response?['message'] ?? 'Failed to load conversations';
        print("CHAT DEBUG: Error message from API: $_conversationsError");
      }
    } catch (e) {
      _conversationsError = e.toString();
      print("CHAT DEBUG: Exception caught: $_conversationsError");
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Fetch Messages for a specific thread
  Future<void> fetchMessages(String conversationId, {int page = 1, int limit = 50, bool showLoading = true}) async {
    if (_activeConversationId != conversationId) {
      _currentMessages = []; // Clear cached messages from previous chat
    }
    _activeConversationId = conversationId;
    
    if (showLoading && _currentMessages.isEmpty) {
      _isLoadingMessages = true;
      notifyListeners();
    }
    _messagesError = null;

    try {
      final String url = "${ApiConfig.chatEndpoint}/conversations/$conversationId/messages?page=$page&limit=$limit";
      final response = await _httpClient.get(url);
      
      if (response != null && response['data'] != null) {
        final data = response['data'];
        
        List<dynamic> fetchedMessages = [];
        if (data is Map && data.containsKey('messages')) {
          fetchedMessages = data['messages'] ?? [];
        } else if (data is List) {
           fetchedMessages = data;
        }
        
        // Preserve any messages that are currently in 'sending' state (optimistic)
        final optimisticMessages = _currentMessages.where((m) => m['status'] == 'sending').toList();
        
        _currentMessages = [...fetchedMessages, ...optimisticMessages];
      } else if (response != null && response['success'] == true) {
        _currentMessages = response['data']?['messages'] ?? [];
      } else {
        _messagesError = response?['message'] ?? 'Failed to load messages';
      }
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Send an outbound message
  Future<bool> sendMessage(String conversationId, String text, {String messageType = 'text'}) async {
    final String? senderId = await AuthService.getUserId();
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Optimistic UI update: show message immediately with 'sending' status
    final optimisticMsg = {
      "_id": tempId, // Temporary ID
      "tempId": tempId,
      "text": text,
      "messageType": messageType,
      "senderType": "telecaller",
      "senderId": senderId,
      "status": "sending",
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };
    
    _currentMessages.add(optimisticMsg);
    notifyListeners();

    return _performSendMessage(conversationId, tempId, optimisticMsg);
  }

  Future<bool> _performSendMessage(String conversationId, String tempId, Map<String, dynamic> msgPayload) async {
    try {
      final String url = "${ApiConfig.chatEndpoint}/conversations/$conversationId/messages";
      final Map<String, dynamic> body = {
        "text": msgPayload['text'],
        "messageType": msgPayload['messageType'],
        "senderType": "telecaller",
        "tempId": tempId,
        if (msgPayload['senderId'] != null) "senderId": msgPayload['senderId'],
      };

      final response = await _httpClient.post(url, body);
      
      final index = _currentMessages.indexWhere((m) => m['tempId'] == tempId || m['_id'] == tempId);
      if (index == -1) return false;

      if (response != null && response['data'] != null) {
        // 2. Update with real ID and mark as 'sent'
        final responseData = response['data'];
        _currentMessages[index] = {
          ..._currentMessages[index],
          "_id": responseData['_id'] ?? _currentMessages[index]['_id'],
          "status": responseData['status'] ?? "sent",
        };
        notifyListeners();
        return true;
      } else if (response != null && response['success'] == true) {
         // Just in case the backend returns success: true without data
         _currentMessages[index] = {
          ..._currentMessages[index],
          "status": "sent",
        };
        notifyListeners();
        return true;
      } else {
        // Mark as failed
        _currentMessages[index] = {
          ..._currentMessages[index],
          "status": "failed",
        };
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      final index = _currentMessages.indexWhere((m) => m['tempId'] == tempId || m['_id'] == tempId);
      if (index != -1) {
        _currentMessages[index] = {
          ..._currentMessages[index],
          "status": "failed",
        };
        notifyListeners();
      }
      return false;
    }
  }

  /// Retry a failed message
  Future<bool> retryMessage(String tempId) async {
    if (_activeConversationId == null) return false;
    
    final index = _currentMessages.indexWhere((m) => m['tempId'] == tempId || m['_id'] == tempId);
    if (index == -1) return false;

    // Reset status to sending
    _currentMessages[index] = {
      ..._currentMessages[index],
      "status": "sending",
    };
    notifyListeners();

    return _performSendMessage(_activeConversationId!, tempId, _currentMessages[index]);
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      final String url = "${ApiConfig.chatEndpoint}/conversations/$conversationId/read";
      await _httpClient.post(url, {});
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  /// Convert chat to Lead
  Future<Map<String, dynamic>> convertToLead(String conversationId, Map<String, dynamic> leadData) async {
    try {
      final String url = "${ApiConfig.chatEndpoint}/conversations/$conversationId/convert-lead";
      print("CHAT DEBUG: [POST] convertToLead endpoint: $url");
      print("CHAT DEBUG: [POST] convertToLead request body: $leadData");
      
      final response = await _httpClient.post(url, leadData);
      print("CHAT DEBUG: [POST] convertToLead response: $response");
      
      return response;
    } catch (e) {
      print('CHAT DEBUG: Error converting to lead: $e');
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  /// Transfer conversation
  Future<bool> transferConversation(String conversationId, String assignedTo) async {
    try {
      final String url = "${ApiConfig.chatEndpoint}/conversations/$conversationId/transfer";
      final response = await _httpClient.post(url, {'assignedTo': assignedTo});
      return response['success'] == true;
    } catch (e) {
      print('Error transferring conversation: $e');
      return false;
    }
  }
}
