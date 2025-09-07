import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sip_ua/sip_ua.dart';

import '../constants/app_constants.dart';
import '../../shared/services/storage_service.dart';
import 'notification_service.dart';

enum SipRegistrationState {
  unregistered,
  registering,
  registered,
  registrationFailed,
}

enum AppCallState {
  none,
  connecting,
  ringing,
  answered,
  held,
  muted,
  ended,
  failed,
}

class CallInfo {
  final String id;
  final String remoteNumber;
  final String remoteName;
  final AppCallState state;
  final DateTime startTime;
  final bool isIncoming;
  final bool isOnHold;
  final bool isMuted;
  final bool isSpeakerOn;

  CallInfo({
    required this.id,
    required this.remoteNumber,
    required this.remoteName,
    required this.state,
    required this.startTime,
    required this.isIncoming,
    this.isOnHold = false,
    this.isMuted = false,
    this.isSpeakerOn = false,
  });

  CallInfo copyWith({
    String? id,
    String? remoteNumber,
    String? remoteName,
    AppCallState? state,
    DateTime? startTime,
    bool? isIncoming,
    bool? isOnHold,
    bool? isMuted,
    bool? isSpeakerOn,
  }) {
    return CallInfo(
      id: id ?? this.id,
      remoteNumber: remoteNumber ?? this.remoteNumber,
      remoteName: remoteName ?? this.remoteName,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      isIncoming: isIncoming ?? this.isIncoming,
      isOnHold: isOnHold ?? this.isOnHold,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }
}

class SipService extends ChangeNotifier with WidgetsBindingObserver implements SipUaHelperListener {
  static final SipService _instance = SipService._internal();
  static SipService get instance => _instance;
  SipService._internal();

  SIPUAHelper? _sipHelper;
  SipRegistrationState _registrationState = SipRegistrationState.unregistered;
  CallInfo? _currentCall;
  final Map<String, Call> _activeCalls = {};
  Timer? _connectionCheckTimer;
  Timer? _reregistrationTimer;
  
  // Store credentials for re-registration
  Map<String, dynamic>? _lastCredentials;
  bool _isReconnecting = false;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;

  // Stream controllers for real-time updates
  final StreamController<SipRegistrationState> _registrationStateController =
      StreamController<SipRegistrationState>.broadcast();
  final StreamController<CallInfo?> _currentCallController =
      StreamController<CallInfo?>.broadcast();

  // Getters
  SipRegistrationState get registrationState => _registrationState;
  CallInfo? get currentCall => _currentCall;
  bool get isRegistered =>
      _registrationState == SipRegistrationState.registered;
  bool get hasActiveCall =>
      _currentCall != null && _currentCall!.state != AppCallState.ended;

  // Streams
  Stream<SipRegistrationState> get registrationStateStream =>
      _registrationStateController.stream;
  Stream<CallInfo?> get currentCallStream => _currentCallController.stream;

  Future<void> initialize() async {
    try {
      debugPrint('SIP Service: Starting initialization...');
      if (_sipHelper != null) {
        debugPrint('SIP Service: Already initialized, skipping...');
        return;
      }
      
      _sipHelper = SIPUAHelper();
      if (_sipHelper == null) {
        throw Exception('Failed to create SIPUAHelper instance');
      }
      
      _sipHelper!.addSipUaHelperListener(this);
      debugPrint('SIP Service: Helper created and listener added');

      // Add app lifecycle observer for iOS (not available on web)
      if (!kIsWeb) {
        try {
          WidgetsBinding.instance.addObserver(this);
          debugPrint('SIP Service: Added app lifecycle observer for iOS');
        } catch (e) {
          debugPrint('SIP Service: Could not add lifecycle observer: $e');
        }
      }

      // Try to auto-register if credentials are stored
      final credentials = await StorageService.instance.getCredentials();
      if (credentials != null) {
        debugPrint('We have stored SIP credentials');
        await _autoRegister(credentials);
      }
      debugPrint('SIP Service: Initialization complete');
    } catch (e) {
      debugPrint('Error initializing SIP service: $e');
      // Reset helper on initialization failure
      _sipHelper = null;
      rethrow;
    }
  }

  Future<void> _autoRegister(Map<String, dynamic> credentials) async {
    try {
      await register(
        name: credentials['name'],
        username: credentials['username'],
        password: credentials['password'],
        domain: credentials['domain'],
        wss: credentials['wss'],
      );
    } catch (e) {
      debugPrint('Auto-registration failed: $e');
    }
  }

  Future<bool> register(
      {required String name,
      required String username,
      required String password,
      required String domain,
      required String wss}) async {
    try {
      _updateRegistrationState(SipRegistrationState.registering);
      debugPrint('Register: loaded: $name');
      
      // Log all parameters for debugging
      debugPrint('Register: name=$name, username=$username, domain=$domain, wss=$wss');
      debugPrint('Register: password length=${password.length}');
      
      final settings = UaSettings();
      
      // Validate and set WebSocket URL
      final wsUrl = 'wss://$wss';
      debugPrint('Register: WebSocket URL=$wsUrl');
      settings.webSocketUrl = wsUrl;
      
      // Validate and set SIP URI
      final sipUri = 'sip:$username@$domain';
      debugPrint('Register: SIP URI=$sipUri');
      settings.uri = sipUri;
      
      // Set other required settings
      settings.authorizationUser = username;
      settings.password = password;
      settings.displayName = name;
      settings.userAgent = '${AppConstants.appName}/${AppConstants.appVersion}';
      
      // Add additional required settings based on sip_ua documentation
      settings.register = true;
      settings.transportType = TransportType.WS;
      
      // Keep connection alive settings
      settings.connectionRecoveryMinInterval = 2;
      settings.connectionRecoveryMaxInterval = 30;
      
      // Additional settings to maintain connection
      debugPrint('Register: Connection recovery settings configured');
      
      // WebSocket settings for security (if available)
      try {
        settings.webSocketSettings.allowBadCertificate = false; // Trust valid certificates
        settings.webSocketSettings.userAgent = settings.userAgent;
        
        // Platform-specific settings with optimizations for large messages
        if (kIsWeb) {
          debugPrint('Register: Applying web-specific WebSocket settings');
          settings.webSocketSettings.extraHeaders = <String, String>{
            'User-Agent': settings.userAgent ?? 'Ringplus/1.0.0',
            'Origin': 'https://phone.ringplus.co.uk',
            'Sec-WebSocket-Protocol': 'sip',
          };
        } else {
          debugPrint('Register: Applying mobile-specific WebSocket settings with large message support');
          settings.webSocketSettings.extraHeaders = <String, String>{
            'User-Agent': settings.userAgent ?? 'Ringplus/1.0.0',
            'Origin': 'https://phone.ringplus.co.uk',
            'Sec-WebSocket-Protocol': 'sip',
            'Sec-WebSocket-Extensions': 'permessage-deflate',
          };
        }
      } catch (e) {
        debugPrint('Register: WebSocket settings not available: $e');
      }
      
      debugPrint('Register: Settings configured - URI: ${settings.uri}, WSS: ${settings.webSocketUrl}, Auth User: ${settings.authorizationUser}, Display Name: ${settings.displayName}');

      // WebRTC settings
      debugPrint('Register: Setting DTMF mode...');
      settings.dtmfMode = DtmfMode.RFC2833;
      
      // ICE servers for better connectivity - reduced for smaller SDP
      try {
        settings.iceServers = [
          {'urls': 'stun:stun.l.google.com:19302'},
        ];
        debugPrint('Register: ICE servers configured (reduced for SDP optimization)');
      } catch (e) {
        debugPrint('Register: Failed to set ICE servers: $e');
      }
      
      // ICE gathering timeout to reduce candidate collection time
      try {
        settings.iceGatheringTimeout = 3000; // 3 seconds instead of default
        debugPrint('Register: ICE gathering timeout set to 3 seconds');
      } catch (e) {
        debugPrint('Register: Failed to set ICE gathering timeout: $e');
      }
      
      debugPrint('Register: SIP helper instance: $_sipHelper');
      if (_sipHelper == null) {
        debugPrint('SIP helper is null, re-initializing...');
        _sipHelper = SIPUAHelper();
        _sipHelper!.addSipUaHelperListener(this);
      }
      
      if (_sipHelper == null) {
        throw Exception(
            "SIP service failed to initialize. Unable to create SIPUAHelper.");
      }
      
      debugPrint('Register: Starting SIP helper with settings...');
      
      // Add web platform check for SIP UA library compatibility
      if (kIsWeb) {
        debugPrint('Register: Running on web platform - checking WebRTC support');
      }
      
      try {
        await _sipHelper!.start(settings);
        debugPrint('Register: SIP helper started successfully');
      } catch (startError) {
        debugPrint('Register: SIP helper start failed: $startError');
        debugPrint('Register: Stack trace: ${StackTrace.current}');
        
        // For web platform, provide more specific error handling
        if (kIsWeb) {
          debugPrint('Register: Web platform error - this might be due to WebRTC limitations in browser');
          throw Exception('SIP registration failed on web platform: $startError. WebRTC/SIP might not be fully supported in browser environment.');
        }
        
        throw Exception('Failed to start SIP helper: $startError');
      }
      debugPrint('Register: loaded2');
      // Store credentials on successful registration
      await StorageService.instance.storeCredentials(
        name: name,
        username: username,
        password: password,
        domain: domain,
        wss: wss,
      );
      
      // Store credentials for re-registration
      _lastCredentials = {
        'name': name,
        'username': username,
        'password': password,
        'domain': domain,
        'wss': wss,
      };
      
      debugPrint('Register: loaded3');
      return true;
    } catch (e) {
      debugPrint('Registration failed: $e');
      _updateRegistrationState(SipRegistrationState.registrationFailed);
      return false;
    }
  }

  Future<void> unregister() async {
    try {
      _isReconnecting = false; // Prevent auto-reconnection
      _lastCredentials = null; // Clear stored credentials
      _connectionCheckTimer?.cancel();
      _reregistrationTimer?.cancel();
      
      _sipHelper?.stop();
      await StorageService.instance.clearCredentials();
      _updateRegistrationState(SipRegistrationState.unregistered);
      _updateCurrentCall(null);
    } catch (e) {
      debugPrint('Unregistration failed: $e');
    }
  }

  Future<String?> makeCall(String number) async {
    try {
      debugPrint('Make call: Checking registration status - $isRegistered');
      debugPrint('Make call: Registration state - $_registrationState');
      
      if (!isRegistered) {
        debugPrint('Make call failed: Not registered. Current state: $_registrationState');
        throw Exception('Not registered');
      }

      if (_sipHelper == null) {
        debugPrint('Make call failed: SIP helper is null');
        throw Exception('SIP service not initialized');
      }

      debugPrint('Make call: Starting call to $number');
      
      // Create SIP URI for the call - use the stored domain from credentials
      final credentials = await StorageService.instance.getCredentials();
      final domain = credentials?['domain'] ?? 'unknown';
      final sipUri = 'sip:$number@$domain';
      debugPrint('Make call: SIP URI - $sipUri');

      // Make the actual SIP call using the correct API
      final success = await _sipHelper!.call(sipUri, voiceOnly: true);
      
      if (success) {
        // Generate a temporary call ID for immediate tracking (will be updated with real ID in callbacks)
        final tempCallId = DateTime.now().millisecondsSinceEpoch.toString();
        debugPrint('Make call: Call initiated successfully with temporary tracking ID - $tempCallId');
        
        final callInfo = CallInfo(
          id: tempCallId,
          remoteNumber: number,
          remoteName: number, // Will be updated when call connects
          state: AppCallState.connecting,
          startTime: DateTime.now(),
          isIncoming: false,
        );

        _updateCurrentCall(callInfo);

        // Add to call history
        await _addToCallHistory(callInfo);

        debugPrint('Make call: Successfully initiated call');
        return tempCallId;
      } else {
        debugPrint('Make call failed: SIP helper returned false');
        throw Exception('Failed to initiate call');
      }
    } catch (e) {
      debugPrint('Make call failed: $e');
      debugPrint('Make call failed: Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<void> answerCall(String callId) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.answer(_buildCallOptions());
        _updateCurrentCall(
            _currentCall?.copyWith(state: AppCallState.answered));
      }
    } catch (e) {
      debugPrint('Answer call failed: $e');
    }
  }

  Future<void> hangupCall(String callId) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.hangup();
        _activeCalls.remove(callId);
        _updateCurrentCall(_currentCall?.copyWith(state: AppCallState.ended));

        // Clear current call after a delay
        Timer(const Duration(seconds: 2), () {
          if (_currentCall?.state == AppCallState.ended) {
            _updateCurrentCall(null);
          }
        });
      }
    } catch (e) {
      debugPrint('Hangup call failed: $e');
    }
  }

  Future<void> holdCall(String callId) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.hold();
        _updateCurrentCall(_currentCall?.copyWith(
          state: AppCallState.held,
          isOnHold: true,
        ));
      }
    } catch (e) {
      debugPrint('Hold call failed: $e');
    }
  }

  Future<void> unholdCall(String callId) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.unhold();
        _updateCurrentCall(_currentCall?.copyWith(
          state: AppCallState.answered,
          isOnHold: false,
        ));
      }
    } catch (e) {
      debugPrint('Unhold call failed: $e');
    }
  }

  Future<void> muteCall(String callId, bool mute) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.mute(mute, mute); // mute audio
        _updateCurrentCall(_currentCall?.copyWith(isMuted: mute));
      }
    } catch (e) {
      debugPrint('Mute call failed: $e');
    }
  }

  Future<void> setSpeaker(String callId, bool speaker) async {
    try {
      // This would typically involve WebRTC audio routing
      _updateCurrentCall(_currentCall?.copyWith(isSpeakerOn: speaker));
    } catch (e) {
      debugPrint('Set speaker failed: $e');
    }
  }

  Future<void> sendDTMF(String callId, String digit) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.sendDTMF(digit);
      }
    } catch (e) {
      debugPrint('Send DTMF failed: $e');
    }
  }

  Future<void> transferCall(String callId, String target) async {
    try {
      final call = _activeCalls[callId];
      if (call != null) {
        call.refer(target);
      }
    } catch (e) {
      debugPrint('Transfer call failed: $e');
    }
  }

  Map<String, dynamic> _buildCallOptions() {
    return {
      'mediaConstraints': {
        'audio': true,
        'video': false,
      },
      'rtcOfferConstraints': {
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': false,
        },
        'optional': [],
      },
    };
  }

  void _updateRegistrationState(SipRegistrationState state) {
    _registrationState = state;
    _registrationStateController.add(state);
    notifyListeners();
  }

  void _updateCurrentCall(CallInfo? call) {
    debugPrint('SipService: _updateCurrentCall called - callId: ${call?.id}, state: ${call?.state}');
    _currentCall = call;
    _currentCallController.add(call);
    debugPrint('SipService: Call state added to stream - ${call?.state}');
    notifyListeners();
  }

  Future<void> _addToCallHistory(CallInfo callInfo) async {
    final historyEntry = {
      'id': callInfo.id,
      'number': callInfo.remoteNumber,
      'name': callInfo.remoteName,
      'timestamp': callInfo.startTime.millisecondsSinceEpoch,
      'isIncoming': callInfo.isIncoming,
      'duration': 0, // Will be updated when call ends
      'type': callInfo.isIncoming ? 'incoming' : 'outgoing',
    };

    await StorageService.instance.addCallToHistory(historyEntry);
  }

  // SIP UA Helper callbacks
  @override
  void registrationStateChanged(RegistrationState state) {
    debugPrint('SIP Service: Registration state changed to ${state.state} - ${state.cause}');
    
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        debugPrint('SIP Service: Successfully registered');
        _updateRegistrationState(SipRegistrationState.registered);
        _reconnectionAttempts = 0; // Reset reconnection attempts on successful registration
        _isReconnecting = false;
        _startConnectionKeepAlive();
        break;
      case RegistrationStateEnum.UNREGISTERED:
        debugPrint('SIP Service: Unregistered - ${state.cause}');
        _updateRegistrationState(SipRegistrationState.unregistered);
        
        // Only auto-reconnect on actual failures, not normal unregistration
        // Check if this is an unexpected disconnection (not status_code 200 which is normal unregister)
        if (_lastCredentials != null && !_isReconnecting && state.cause?.status_code != 200) {
          debugPrint('SIP Service: Unexpected unregistration (code: ${state.cause?.status_code}), scheduling reconnection');
          _scheduleReconnection();
        } else if (state.cause?.status_code == 200) {
          debugPrint('SIP Service: Normal unregistration (code: 200), not reconnecting');
        }
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        debugPrint('SIP Service: Registration failed - ${state.cause}');
        _updateRegistrationState(SipRegistrationState.registrationFailed);
        
        // Attempt reconnection with exponential backoff for registration failures
        if (_lastCredentials != null && _reconnectionAttempts < _maxReconnectionAttempts) {
          _scheduleReconnection();
        }
        break;
      case RegistrationStateEnum.NONE:
        debugPrint('SIP Service: Registration state NONE - ${state.cause}');
        _updateRegistrationState(SipRegistrationState.unregistered);
        
        // Only reconnect for NONE state if it's really an unexpected disconnection
        if (_lastCredentials != null && !_isReconnecting && state.cause?.status_code != 200) {
          debugPrint('SIP Service: Unexpected NONE state (code: ${state.cause?.status_code}), scheduling reconnection');
          _scheduleReconnection();
        }
        break;
      case null:
        debugPrint('SIP Service: Registration state NULL - ${state.cause}');
        _updateRegistrationState(SipRegistrationState.unregistered);
        
        // Only reconnect for NULL state if it's really an unexpected disconnection
        if (_lastCredentials != null && !_isReconnecting && state.cause?.status_code != 200) {
          debugPrint('SIP Service: Unexpected NULL state (code: ${state.cause?.status_code}), scheduling reconnection');
          _scheduleReconnection();
        }
        break;
    }
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    final callId = call.id ?? 'unknown';
    debugPrint('SIP Service: Call state changed - $callId - ${callState.state}');
    
    // Store the call in our active calls if not already there
    if (!_activeCalls.containsKey(callId)) {
      _activeCalls[callId] = call;
      debugPrint('SIP Service: Added new call to active calls - $callId');
    }

    // Map SIP call states to our app call states
    AppCallState appState;
    switch (callState.state) {
      case CallStateEnum.CALL_INITIATION:
        appState = AppCallState.connecting;
        break;
      case CallStateEnum.PROGRESS:
        appState = AppCallState.ringing;
        break;
      case CallStateEnum.CONNECTING:
        appState = AppCallState.connecting;
        break;
      case CallStateEnum.CONFIRMED:
        appState = AppCallState.answered;
        break;
      case CallStateEnum.ENDED:
        appState = AppCallState.ended;
        break;
      case CallStateEnum.FAILED:
        appState = AppCallState.failed;
        break;
      case CallStateEnum.ACCEPTED:
        appState = AppCallState.answered;
        break;
      default:
        appState = AppCallState.connecting;
        break;
    }

    // Update current call info or create new one
    debugPrint('SIP Service: Checking call update conditions - currentCallId: ${_currentCall?.id}, eventCallId: $callId, currentCall is null: ${_currentCall == null}');
    // Accept updates if: exact match, no current call, or we have a current call but this is a new real SIP call
    if (_currentCall?.id == callId || _currentCall == null || (_currentCall != null && !_currentCall!.isIncoming)) {
      debugPrint('SIP Service: Condition met - updating call info');
      final callInfo = CallInfo(
        id: callId,
        remoteNumber: call.remote_display_name ?? call.remote_identity ?? 'Unknown',
        remoteName: call.remote_display_name ?? 'Unknown',
        state: appState,
        startTime: _currentCall?.startTime ?? DateTime.now(),
        isIncoming: call.direction == 'incoming',
      );
      
      debugPrint('SIP Service: About to update current call - $callId - $appState');
      _updateCurrentCall(callInfo);
      debugPrint('SIP Service: Updated current call - $callId - $appState');
      
      // Remove from active calls if ended
      if (appState == AppCallState.ended || appState == AppCallState.failed) {
        _activeCalls.remove(callId);
        debugPrint('SIP Service: Removed call from active calls - $callId');
        
        // Clear current call after a delay
        Timer(const Duration(seconds: 2), () {
          if (_currentCall?.id == callId) {
            _updateCurrentCall(null);
          }
        });
      }
    } else {
      debugPrint('SIP Service: Condition NOT met - skipping call update. Current call ID: ${_currentCall?.id} vs Event call ID: $callId');
    }
  }

  void onNewCall(Call call) {
    onIncomingCall(call);
  }

  void onIncomingCall(Call call) {
    final callInfo = CallInfo(
      id: call.id ?? 'unknown',
      remoteNumber: call.remote_identity?.toString() ?? 'Unknown',
      remoteName: call.remote_display_name?.toString() ?? 'Unknown',
      state: AppCallState.ringing,
      startTime: DateTime.now(),
      isIncoming: true,
    );

    _activeCalls[call.id ?? 'unknown'] = call;
    _updateCurrentCall(callInfo);

    // Show incoming call notification
    NotificationService.instance.showIncomingCallNotification(
      callId: call.id ?? 'unknown',
      callerName: callInfo.remoteName,
      callerNumber: callInfo.remoteNumber,
    );

    // Add to call history
    _addToCallHistory(callInfo);
  }

  @override
  void transportStateChanged(TransportState state) {
    debugPrint('SIP Service: Transport state changed to ${state.state}');
    
    switch (state.state) {
      case TransportStateEnum.CONNECTED:
        debugPrint('SIP Service: Transport connected');
        break;
      case TransportStateEnum.CONNECTING:
        debugPrint('SIP Service: Transport connecting...');
        break;
      case TransportStateEnum.DISCONNECTED:
        debugPrint('SIP Service: Transport disconnected - ${state.cause}');
        // Only reconnect on unexpected transport disconnections, not local closes
        if (_lastCredentials != null && !_isReconnecting && 
            state.cause?.cause != 'close by local' && state.cause?.status_code != 0) {
          debugPrint('SIP Service: Unexpected transport disconnection, scheduling reconnection...');
          _scheduleReconnection();
        } else {
          debugPrint('SIP Service: Normal transport disconnection, not reconnecting');
        }
        break;
      case TransportStateEnum.NONE:
        debugPrint('SIP Service: Transport state NONE - ${state.cause}');
        break;
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    // Handle new SIP messages if needed
    debugPrint('New SIP message received');
  }

  @override
  void onNewNotify(Notify ntf) {
    // Handle new SIP notifications if needed
    debugPrint('New SIP notify received');
  }

  @override
  void onNewReinvite(ReInvite reinvite) {
    // Handle SIP reinvites if needed
    debugPrint('New SIP reinvite received');
  }

  // App lifecycle management for iOS
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return; // Lifecycle changes not needed on web
    
    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('SIP Service: App paused - keeping SIP connection alive');
        break;
      case AppLifecycleState.resumed:
        debugPrint('SIP Service: App resumed - checking SIP connection');
        _checkAndRecoverConnection();
        break;
      case AppLifecycleState.inactive:
        debugPrint('SIP Service: App inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('SIP Service: App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('SIP Service: App hidden');
        break;
    }
  }

  void _checkAndRecoverConnection() async {
    if (_sipHelper != null && !isRegistered) {
      debugPrint('SIP Service: Connection lost, attempting to recover...');
      final credentials = await StorageService.instance.getCredentials();
      if (credentials != null) {
        await _autoRegister(credentials);
      }
    } else if (_sipHelper != null && isRegistered) {
      debugPrint('SIP Service: Connection is healthy - already registered');
    }
  }

  // Connection keep-alive mechanism
  void _startConnectionKeepAlive() {
    _connectionCheckTimer?.cancel();
    
    // Check connection every 30 seconds
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_sipHelper != null) {
        debugPrint('SIP Service: Keep-alive check - Registration state: $_registrationState');
        
        // If we're not registered but have credentials, attempt re-registration
        if (!isRegistered && _lastCredentials != null && !_isReconnecting) {
          debugPrint('SIP Service: Keep-alive detected disconnection, reconnecting...');
          _scheduleReconnection();
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Schedule reconnection with exponential backoff
  void _scheduleReconnection() {
    if (_isReconnecting || _lastCredentials == null) {
      debugPrint('SIP Service: Reconnection already in progress or no credentials');
      return;
    }

    _isReconnecting = true;
    _reconnectionAttempts++;
    
    // Calculate backoff delay: 2^attempts seconds, max 60 seconds
    final delay = Duration(
      seconds: (2 << _reconnectionAttempts).clamp(2, 60),
    );
    
    debugPrint('SIP Service: Scheduling reconnection attempt $_reconnectionAttempts in ${delay.inSeconds}s');
    
    _reregistrationTimer?.cancel();
    _reregistrationTimer = Timer(delay, () async {
      if (_lastCredentials != null) {
        debugPrint('SIP Service: Executing reconnection attempt $_reconnectionAttempts');
        
        try {
          // DON'T call stop() - this is what's causing the loop!
          // The sip_ua library manages UA instances automatically
          
          // Just attempt to register with existing helper
          final credentials = _lastCredentials!;
          
          // Check if helper exists and is not null
          if (_sipHelper == null) {
            debugPrint('SIP Service: Helper is null, re-initializing...');
            await initialize();
          }
          
          final success = await register(
            name: credentials['name'],
            username: credentials['username'],
            password: credentials['password'],
            domain: credentials['domain'],
            wss: credentials['wss'],
          );
          
          if (!success) {
            debugPrint('SIP Service: Reconnection attempt $_reconnectionAttempts failed');
            _isReconnecting = false;
            // Schedule another attempt if we haven't exceeded max attempts
            if (_reconnectionAttempts < _maxReconnectionAttempts) {
              _scheduleReconnection();
            } else {
              debugPrint('SIP Service: Max reconnection attempts reached, giving up');
            }
          } else {
            debugPrint('SIP Service: Reconnection attempt $_reconnectionAttempts succeeded');
          }
        } catch (e) {
          debugPrint('SIP Service: Reconnection attempt $_reconnectionAttempts error: $e');
          _isReconnecting = false;
          
          // Schedule another attempt if we haven't exceeded max attempts
          if (_reconnectionAttempts < _maxReconnectionAttempts) {
            _scheduleReconnection();
          } else {
            debugPrint('SIP Service: Max reconnection attempts reached, giving up');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    _reregistrationTimer?.cancel();
    _registrationStateController.close();
    _currentCallController.close();
    _sipHelper?.removeSipUaHelperListener(this);
    if (!kIsWeb) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (e) {
        debugPrint('SIP Service: Could not remove lifecycle observer: $e');
      }
    }
    super.dispose();
  }
}
