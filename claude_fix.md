We need to update our app. Remove welcome page entirely.
Initial page: /splash → SplashScreen.
After splash:
If user is logged in → navigate to /keypad
If user is not logged in → naviagate to /login.
When the app starts, it should show a **login page** with email + password fields.

On the login page we don't need the advanced settings.

1. On submit, POST (form-encoded) to:
   POST https://api.ringplus.co.uk/v1/signin

   Body:
   {
   "email": "string",
   "password": "string"
   }

   Response:
   {
   "access_token": "string",
   "refresh_token": "string",
   "token_type": "string"
   }

2. After login:

   - Save `access_token`, `refresh_token` in local storage (e.g. `shared_preferences`).
   - Decode the JWT `access_token` payload to get `exp`. Save `token_expires_at`.

3. For every API call:

   - Before sending, check if `now < token_expires_at - 60*1000` (1 min before expiry).
     - If true → use the existing `access_token`.
     - Else → refresh the token.

4. Token refresh:

   - Call: PUT https://api.ringplus.co.uk/v1/refresh
   - Body:
     {
     "refresh_token": "string"
     }
   - Save the new `access_token` + update its `exp`.

5. For all API requests, set the header:
   Authorization: "Bearer <access_token>"

Please generate a Flutter example using:

- `http` for networking
- `shared_preferences` for storage
- Proper async/await pattern
- A simple LoginPage widget
- An ApiClient class to handle requests + token refresh

---

'POST' \
 'https://api.ringplus.co.uk/v1/signin' \
 -H 'accept: application/json' \
 -H 'Content-Type: application/x-www-form-urlencoded' \
 -d 'username=user%40example.com&password=string'

Content type it has to x-www-form-urlencoded the signin

---

In main.dar: we have SipService.instance.initialize(). We need to initialize, only after a successfull Login /login.
If there is already hasValidToken. Then we need to call an API to get extension details.
if there is no valid token. We need login first before calling API to get extensions details.

API to GET Extension details: https://api.ringplus.co.uk/v1/extensions/mobile
It will return:

[
{
"name": "Ravi",
"extension": 1002,
"domain": "408708399.ringplus.co.uk",
"password": "1Z(OeDvN9dt0(f",
"wss": "phone.ringplus.co.uk:5622"
}
]

---

I have added an image in mockup folder called dialpad.png. Build exactly the same dialpad with on left top corner Name and Extension number dynamically. And right corner show online if Extension is Registered if not Offline.
Dial button need to be active and purple when at least one number is entered.

---

I have placed the output image in mockup dialpad_output.png. Keep Dial button and delete button in the position.
When numbers are entered the buttons are changing position.

---

flutter: [2025-09-05 23:05:28.464] Level.info ua.dart:372 ::: Closing connection\^[[0m
flutter: [2025-09-05 23:05:28.466] Level.debug socket_transport.dart:99 ::: Transport close()
flutter: [2025-09-05 23:05:28.467] Level.debug web_socket.dart:119 ::: disconnect()

- Is only happening when the restart and the credential is already in the storage. If I do logout and login, registration works fine and connection is not closed.
- Once logged in and registrerd Offline button become Online when we start to dial a number.

---

I have placed in mockup on_call_screen.png, when we dial and number and call. It should open call screen. Make sure hangup button works. Instead of putting End Call button replace it with a red round button in the same style as the dial button.

---

on CallStateEnum.FAILED, we need to come back to Keypad screen.

---

Auth: Extension details - Name: Ravi, Extension: 1002, Domain: 408708399.ringplus.co.uk, WSS: phone.ringplus.co.uk:4643
SIP Service: Starting initialization...
SIP Service: Helper created and listener added
Error initializing SIP service: Unsupported operation: Platform.\_operatingSystem
Auth: Error initializing SIP: Unsupported operation: Platform.\_operatingSystem

---

From IOS:

flutter: Make call: Registration state - SipRegistrationState.registered
flutter: Make call: Starting call to 1001
flutter: Make call: SIP URI - sip:1001@408708399.ringplus.co.uk
flutter: [2025-09-07 14:14:50.395] Level.debug ua.dart:252 ::: call()
flutter: [2025-09-07 14:14:50.396] Level.debug rtc_session.dart:70 ::: new
flutter: [2025-09-07 14:14:50.397] Level.debug rtc_session.dart:238 ::: connect()
flutter: Make call: Call initiated successfully with temporary tracking ID - 1757247290403
flutter: SipService: \_updateCurrentCall called - callId: 1757247290403, state: AppCallState.connecting
flutter: SipService: Call state added to stream - AppCallState.connecting
flutter: [2025-09-07 14:14:50.407] Level.debug rtc_session.dart:1655 ::: emit "peerconnection"
flutter: [2025-09-07 14:14:50.407] Level.debug rtc_session.dart:3219 ::: newRTCSession()
flutter: [2025-09-07 14:14:50.407] Level.debug sip_ua_helper.dart:234 ::: newRTCSession => Instance of 'EventNewRTCSession'
flutter: SIP Service: Call state changed - 774mubc5godf7juzbepnpoueaopz3c - CallStateEnum.CALL_INITIATION
flutter: SIP Service: Added new call to active calls - 774mubc5godf7juzbepnpoueaopz3c
flutter: SIP Service: Checking call update conditions - currentCallId: 1757247290403, eventCallId: 774mubc5godf7juzbepnpoueaopz3c, currentCall is null: false
flutter: SIP Service: Condition met - updating call info
flutter: SIP Service: About to update current call - 774mubc5godf7juzbepnpoueaopz3c - AppCallState.connecting
flutter: SipService: \_updateCurrentCall called - callId: 774mubc5godf7juzbepnpoueaopz3c, state: AppCallState.connecting
flutter: SipService: Call state added to stream - AppCallState.connecting
flutter: SIP Service: Updated current call - 774mubc5godf7juzbepnpoueaopz3c - AppCallState.connecting
flutter: Make call: Successfully initiated call
flutter: InCallScreen: Setting up call state listener for callId: 1757247290403
flutter: [2025-09-07 14:14:50.430] Level.debug rtc_session.dart:3224 ::: session connecting
flutter: [2025-09-07 14:14:50.431] Level.debug rtc_session.dart:3225 ::: emit "connecting"
flutter: [2025-09-07 14:14:50.431] Level.debug sip_ua_helper.dart:277 ::: call connecting
flutter: SIP Service: Call state changed - 774mubc5godf7juzbepnpoueaopz3c - CallStateEnum.CONNECTING
flutter: SIP Service: Checking call update conditions - currentCallId: 774mubc5godf7juzbepnpoueaopz3c, eventCallId: 774mubc5godf7juzbepnpoueaopz3c, currentCall is null: false
flutter: SIP Service: Condition met - updating call info
flutter: SIP Service: About to update current call - 774mubc5godf7juzbepnpoueaopz3c - AppCallState.connecting
flutter: SipService: \_updateCurrentCall called - callId: 774mubc5godf7juzbepnpoueaopz3c, state: AppCallState.connecting
flutter: SipService: Call state added to stream - AppCallState.connecting
flutter: SIP Service: Updated current call - 774mubc5godf7juzbepnpoueaopz3c - AppCallState.connecting
flutter: [2025-09-07 14:14:50.432] Level.debug rtc_session.dart:1662 ::: createLocalDescription()
flutter: InCallScreen: Received call state update - callId: 774mubc5godf7juzbepnpoueaopz3c, state: AppCallState.connecting, widgetCallId: 1757247290403
flutter: SIP Service: Call state changed - 774mubc5godf7juzbepnpoueaopz3c - CallStateEnum.STREAM
flutter: SIP Service: Checking call update conditions - currentCallId: 774mubc5godf7juzbepnpoueaopz3c, eventCallId: 774mubc5godf7juzbepnpoueaopz3c, currentCall is null: false
flutter: SIP Service: Condition met - updating call info
flutter: SIP Service: About to update current call - 774mubc5godf7juzbepnpoueaopz3c - AppCallState.connecting
flutter: SipService: \_updateCurrentCall called - callId: 774mubc5godf7juzbepnpoueaopz3c, state: AppCallState.connecting
flutter: SipService: Call state added to stream - AppCallState.connecting
flutter: SIP Service: Updated current call - 774mubc5godf7juzbepnpoueaopz3c - AppCallState.connecting
flutter: InCallScreen: Received call state update - callId: 774mubc5godf7juzbepnpoueaopz3c, state: AppCallState.connecting, widgetCallId: 1757247290403
flutter: [2025-09-07 14:14:50.937] Level.debug rtc_session.dart:1722 ::: emit "sdp"
flutter: [2025-09-07 14:14:50.938] Level.debug rtc_session.dart:2395 ::: emit "sending" [request]
flutter: [2025-09-07 14:14:50.939] Level.debug socket_transport.dart:128 ::: Socket Transport send()
flutter: [2025-09-07 14:14:50.940] Level.debug sip_message.dart:276 ::: Outgoing Message: SipMethod.INVITE body: v=0
o=- 3456688998043334879 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0
a=extmap-allow-mixed
a=msid-semantic: WMS ECA5D256-B5CD-482F-9969-26BC855B319D
m=audio 45581 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126
c=IN IP4 88.174.209.3
a=rtcp:9 IN IP4 0.0.0.0
a=candidate:2084073027 1 udp 2122194687 192.168.0.183 50640 typ host generation 0 network-id 1 network-cost 10
a=candidate:4140454980 1 udp 2122063615 10.31.19.52 55919 typ host generation 0 network-id 8 network-cost 900
a=candidate:200451935 1 udp 2121932543 127.0.0.1 55562 typ host generation 0 network-id 6
a=candidate:3587789822 1 udp 2122262783 2a01:e0a:bb4:40e0::79df:4446 58372 typ host generation 0 network-id 2 network-cost 10
a=candidate:3067140329 1 udp 2122131711 2a0d:e487:52f:142e:1959:a49b:1f83:b054 60762 typ host generation 0 network-id 9 network-cost 900
a=candidate:652964740 1 udp 2122005759 ::1 55130 typ host gene
flutter: [2025-09-07 14:14:50.941] Level.debug web_socket.dart:136 ::: send()
flutter: [2025-09-07 14:14:50.943] Level.debug websocket_dart_impl.dart:54 ::: send:

INVITE sip:1001@408708399.ringplus.co.uk SIP/2.0
Via: SIP/2.0/WSS 2c333j35ps31.invalid;branch=z9hG4bK1111604880000000
Max-Forwards: 69
To: <sip:1001@408708399.ringplus.co.uk>
From: "Ravi" <sip:1002@408708399.ringplus.co.uk>;tag=poueaopz3c
Call-ID: 774mubc5godf7juzbepn
CSeq: 2910 INVITE
Contact: <sip:em5ffr91@2c333j35ps31.invalid;transport=WSS;ob>
Content-Type: application/sdp
Session-Expires: 120
Allow: INVITE,ACK,CANCEL,BYE,UPDATE,MESSAGE,OPTIONS,REFER,INFO,NOTIFY
Supported: timer,ice,replaces,outbound
User-Agent: Ringplus/1.0.0
Content-Length: 3044

v=0
o=- 3456688998043334879 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0
a=extmap-allow-mixed
a=msid-semantic: WMS ECA5D256-B5CD-482F-9969-26BC855B319D
m=audio 45581 UDP/TLS/RTP/SAVPF 111 63 9 102 0 8 13 110 126
c=IN IP4 88.174.209.3
a=rtcp:9 IN IP4 0.0.0.0
a=candidate:2084073027 1 udp 2122194687 192.168.0.183 50640 typ host generation 0 network-id 1
flutter: [2025-09-07 14:14:50.983] Level.debug web_socket.dart:102 ::: Closed [1002, null]!
flutter: [2025-09-07 14:14:50.984] Level.debug web_socket.dart:168 ::: WebSocket wss://phone.ringplus.co.uk:4643 closed
flutter: [2025-09-07 14:14:50.986] Level.debug invite_client.dart:60 ::: transport error occurred, deleting transaction z9hG4bK1111604880000000
flutter: [2025-09-07 14:14:50.988] Level.error rtc_session.dart:1423 ::: onTransportError()\^[[0m
flutter: [2025-09-07 14:14:50.990] Level.debug rtc_session.dart:716 ::: terminate()
flutter: [2025-09-07 14:14:50.991] Level.debug rtc_session.dart:741 ::: canceling session
flutter: [2025-09-07 14:14:50.992] Level.debug rtc_session.dart:3268 ::: session failed
flutter: [2025-09-07 14:14:50.993] Level.debug rtc_session.dart:3271 ::: emit "\_failed"
flutter: [2025-09-07 14:14:50.994] Level.debug rtc_session.dart:1501 ::: close()
flutter: [2025-09-07 14:14:50.995] Level.debug rtc_session.dart:3282 ::: emit "failed"
flutter: [2025-09-07 14:14:50.997] Level.debug sip_ua_helper.dart:288 ::: call failed with cause: Code: [500], Cause: Canceled, Reason: SIP ;cause=500 ;text="Connection Error"
flutter: SIP Service: Call state changed - 774mubc5godf7juzbepnpoueaopz3c - CallStateEnum.FAILED

From Chrome:

Make call: Registration state - SipRegistrationState.registered
Make call: Starting call to 1001
Make call: SIP URI - sip:1001@408708399.ringplus.co.uk
[2025-09-07 14:12:25.181] Level.debug null ::: call()
[2025-09-07 14:12:25.185] Level.debug null ::: new
[2025-09-07 14:12:25.188] Level.debug null ::: connect()
[2025-09-07 14:12:25.194] Level.debug null ::: emit "peerconnection"
[2025-09-07 14:12:25.195] Level.debug null ::: newRTCSession()
[2025-09-07 14:12:25.197] Level.debug null ::: newRTCSession => Instance of 'EventNewRTCSession'
SIP Service: Call state changed - 0614545740706461652416s3790a47 - CallStateEnum.CALL_INITIATION
SIP Service: Added new call to active calls - 0614545740706461652416s3790a47
SIP Service: Checking call update conditions - currentCallId: null, eventCallId: 0614545740706461652416s3790a47, currentCall is
null: true
SIP Service: Condition met - updating call info
SIP Service: About to update current call - 0614545740706461652416s3790a47 - AppCallState.connecting
SipService: \_updateCurrentCall called - callId: 0614545740706461652416s3790a47, state: AppCallState.connecting
SipService: Call state added to stream - AppCallState.connecting
SIP Service: Updated current call - 0614545740706461652416s3790a47 - AppCallState.connecting
Make call: Call initiated successfully with temporary tracking ID - 1757247145201
SipService: \_updateCurrentCall called - callId: 1757247145201, state: AppCallState.connecting
SipService: Call state added to stream - AppCallState.connecting
Make call: Successfully initiated call
InCallScreen: Setting up call state listener for callId: 1757247145201
[2025-09-07 14:12:25.893] Level.debug null ::: session connecting
[2025-09-07 14:12:25.894] Level.debug null ::: emit "connecting"
[2025-09-07 14:12:25.896] Level.debug null ::: call connecting
SIP Service: Call state changed - 0614545740706461652416s3790a47 - CallStateEnum.CONNECTING
SIP Service: Checking call update conditions - currentCallId: 1757247145201, eventCallId: 0614545740706461652416s3790a47,
currentCall is null: false
SIP Service: Condition met - updating call info
SIP Service: About to update current call - 0614545740706461652416s3790a47 - AppCallState.connecting
SipService: \_updateCurrentCall called - callId: 0614545740706461652416s3790a47, state: AppCallState.connecting
SipService: Call state added to stream - AppCallState.connecting
SIP Service: Updated current call - 0614545740706461652416s3790a47 - AppCallState.connecting
[2025-09-07 14:12:25.898] Level.debug null ::: createLocalDescription()
InCallScreen: Received call state update - callId: 0614545740706461652416s3790a47, state: AppCallState.connecting, widgetCallId:
1757247145201
SIP Service: Call state changed - 0614545740706461652416s3790a47 - CallStateEnum.STREAM
SIP Service: Checking call update conditions - currentCallId: 0614545740706461652416s3790a47, eventCallId:
0614545740706461652416s3790a47, currentCall is null: false
SIP Service: Condition met - updating call info
SIP Service: About to update current call - 0614545740706461652416s3790a47 - AppCallState.connecting
SipService: \_updateCurrentCall called - callId: 0614545740706461652416s3790a47, state: AppCallState.connecting
SipService: Call state added to stream - AppCallState.connecting
SIP Service: Updated current call - 0614545740706461652416s3790a47 - AppCallState.connecting
InCallScreen: Received call state update - callId: 0614545740706461652416s3790a47, state: AppCallState.connecting, widgetCallId:
1757247145201
[2025-09-07 14:12:26.409] Level.debug null ::: emit "sdp"
[2025-09-07 14:12:26.412] Level.debug null ::: emit "sending" [request]
[2025-09-07 14:12:26.414] Level.debug null ::: Socket Transport send()
[2025-09-07 14:12:26.416] Level.debug null ::: Outgoing Message: SipMethod.INVITE body: v=0
o=- 3333007003474375108 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0
a=extmap-allow-mixed
a=msid-semantic: WMS 94aec60b-2ae8-4b78-adf5-ef5d8c090041
m=audio 34775 UDP/TLS/RTP/SAVPF 111 63 9 0 8 13 110 126
c=IN IP4 88.174.209.3
a=rtcp:9 IN IP4 0.0.0.0
a=candidate:2477250150 1 udp 2122260223 169.254.69.197 57488 typ host generation 0 network-id 3
a=candidate:290064091 1 udp 2122129151 192.168.0.185 49737 typ host generation 0 network-id 1 network-cost 10
a=candidate:2372779730 1 udp 2122197247 2a01:e0a:bb4:40e0::5596:e9d2 63469 typ host generation 0 network-id 2 network-cost 10
a=candidate:1751362651 1 udp 2122068735 fd9d:2d8:4784::2 54049 typ host generation 0 network-id 4 network-cost 50
a=candidate:3498332561 1 udp 1685921535 88.174.209.3 34775 typ srflx raddr 192.168.0.185 rport 49737 generation 0 network-id 1
network-cost 10
a=candidate:1829569266 1 tcp 1518280447 169.254.69.197 9 typ host tcptype active generation 0 network-id 3
a=candidate:4024488527 1 tcp 1518149375 192.168.0.185 9 typ host tcptype active generation 0 network-id 1 network-cost 10
a=candidate:1942448710 1 tcp 1518217471 2a01:e0a:bb4:40e0::5596:e9d2 9 typ host tcptype active generation 0 network-id 2
network-cost 10
a=candidate:2529786063 1 tcp 1518088959 fd9d:2d8:4784::2 9 typ host tcptype active generation 0 network-id 4 network-cost 50
a=ice-ufrag:INjW
a=ice-pwd:gylZdpAZ3SRoI6hNA3Cx+jMU
a=ice-options:trickle
a=fingerprint:sha-256 F0:4D:1A:04:07:BF:3D:C5:4A:C0:17:C5:D5:E7:BD:B6:33:82:B5:84:16:00:9C:10:FB:14:BF:75:30:B4:6F:53
a=setup:actpass
a=mid:0
a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
a=sendrecv
a=msid:94aec60b-2ae8-4b78-adf5-ef5d8c090041 d4660d00-e320-4730-9575-7a89f828f8e5
a=rtcp-mux
a=rtcp-rsize
a=rtpmap:111 opus/48000/2
a=rtcp-fb:111 transport-cc
a=fmtp:111 minptime=10;useinbandfec=1
a=rtpmap:63 red/48000/2
a=fmtp:63 111/111
a=rtpmap:9 G722/8000
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:13 CN/8000
a=rtpmap:110 telephone-event/48000
a=rtpmap:126 telephone-event/8000
a=ssrc:3180635935 cname:JXQrRdS4XF+WHqM+
a=ssrc:3180635935 msid:94aec60b-2ae8-4b78-adf5-ef5d8c090041 d4660d00-e320-4730-9575-7a89f828f8e5

[2025-09-07 14:12:26.418] Level.debug null ::: send()
[2025-09-07 14:12:26.420] Level.debug null ::: send:

INVITE sip:1001@408708399.ringplus.co.uk SIP/2.0
Via: SIP/2.0/WSS d85gjhgezcyn.invalid;branch=z9hG4bK7028820370000000
Max-Forwards: 69
To: <sip:1001@408708399.ringplus.co.uk>
From: "Ravi" <sip:1002@408708399.ringplus.co.uk>;tag=16s3790a47
Call-ID: 06145457407064616524
CSeq: 65 INVITE
Contact: <sip:sssno9un@d85gjhgezcyn.invalid;transport=WSS;ob>
Content-Type: application/sdp
Session-Expires: 120
Allow: INVITE,ACK,CANCEL,BYE,UPDATE,MESSAGE,OPTIONS,REFER,INFO,NOTIFY
Supported: timer,ice,replaces,outbound
User-Agent: Ringplus/1.0.0
Content-Length: 2393

v=0
o=- 3333007003474375108 2 IN IP4 127.0.0.1
s=-
t=0 0
a=group:BUNDLE 0
a=extmap-allow-mixed
a=msid-semantic: WMS 94aec60b-2ae8-4b78-adf5-ef5d8c090041
m=audio 34775 UDP/TLS/RTP/SAVPF 111 63 9 0 8 13 110 126
c=IN IP4 88.174.209.3
a=rtcp:9 IN IP4 0.0.0.0
a=candidate:2477250150 1 udp 2122260223 169.254.69.197 57488 typ host generation 0 network-id 3
a=candidate:290064091 1 udp 2122129151 192.168.0.185 49737 typ host generation 0 network-id 1 network-cost 10
a=candidate:2372779730 1 udp 2122197247 2a01:e0a:bb4:40e0::5596:e9d2 63469 typ host generation 0 network-id 2 network-cost 10
a=candidate:1751362651 1 udp 2122068735 fd9d:2d8:4784::2 54049 typ host generation 0 network-id 4 network-cost 50
a=candidate:3498332561 1 udp 1685921535 88.174.209.3 34775 typ srflx raddr 192.168.0.185 rport 49737 generation 0 network-id 1
network-cost 10
a=candidate:1829569266 1 tcp 1518280447 169.254.69.197 9 typ host tcptype active generation 0 network-id 3
a=candidate:4024488527 1 tcp 1518149375 192.168.0.185 9 typ host tcptype active generation 0 network-id 1 network-cost 10
a=candidate:1942448710 1 tcp 1518217471 2a01:e0a:bb4:40e0::5596:e9d2 9 typ host tcptype active generation 0 network-id 2
network-cost 10
a=candidate:2529786063 1 tcp 1518088959 fd9d:2d8:4784::2 9 typ host tcptype active generation 0 network-id 4 network-cost 50
a=ice-ufrag:INjW
a=ice-pwd:gylZdpAZ3SRoI6hNA3Cx+jMU
a=ice-options:trickle
a=fingerprint:sha-256 F0:4D:1A:04:07:BF:3D:C5:4A:C0:17:C5:D5:E7:BD:B6:33:82:B5:84:16:00:9C:10:FB:14:BF:75:30:B4:6F:53
a=setup:actpass
a=mid:0
a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
a=sendrecv
a=msid:94aec60b-2ae8-4b78-adf5-ef5d8c090041 d4660d00-e320-4730-9575-7a89f828f8e5
a=rtcp-mux
a=rtcp-rsize
a=rtpmap:111 opus/48000/2
a=rtcp-fb:111 transport-cc
a=fmtp:111 minptime=10;useinbandfec=1
a=rtpmap:63 red/48000/2
a=fmtp:63 111/111
a=rtpmap:9 G722/8000
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=rtpmap:13 CN/8000
a=rtpmap:110 telephone-event/48000
a=rtpmap:126 telephone-event/8000
a=ssrc:3180635935 cname:JXQrRdS4XF+WHqM+
a=ssrc:3180635935 msid:94aec60b-2ae8-4b78-adf5-ef5d8c090041 d4660d00-e320-4730-9575-7a89f828f8e5

[2025-09-07 14:12:26.457] Level.debug null ::: Received WebSocket message
[2025-09-07 14:12:26.458] Level.debug null ::: received text message:

SIP/2.0 100 Giving it a try
Via: SIP/2.0/WSS d85gjhgezcyn.invalid;received=88.174.209.3;rport=41802;branch=z9hG4bK7028820370000000
To: <sip:1001@408708399.ringplus.co.uk>
From: "Ravi" <sip:1002@408708399.ringplus.co.uk>;tag=16s3790a47
Call-ID: 06145457407064616524
CSeq: 65 INVITE
Server: RingPlus
Content-Length: 0

[2025-09-07 14:12:26.461] Level.debug null ::: receiveInviteResponse() current status: 1
[2025-09-07 14:12:26.471] Level.debug null ::: Received WebSocket message

When testing I have no issue but with IOS, Websocket is getting closed. I can see this error in my opensips logs for Ios Invite: ERROR:proto_wss:ws_process: Made 4 read attempts but message is not complete yet - closing connection

---

## When calling a number InCallScreen shows up and timer starts. We should only starts showing timer when call is answered/established. Prior to it we should show if call is connecting/trying/ringing before starts timer once answered.

there is a small bug. Connecting and Ringing shows properly but once call is answered timer shows up but very quickly is replaced by Connecting text.
I guess when state change timer is hidden by the state.

---

I have added an image in mockup/new_keypad.jpg. Bring same look to the current keypad

---
