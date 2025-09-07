class ExtensionDetails {
  final String name;
  final int extension;
  final String domain;
  final String password;
  final String wss;

  ExtensionDetails({
    required this.name,
    required this.extension,
    required this.domain,
    required this.password,
    required this.wss,
  });

  factory ExtensionDetails.fromJson(Map<String, dynamic> json) {
    return ExtensionDetails(
      name: json['name'] ?? '',
      extension: json['extension'] ?? 0,
      domain: json['domain'] ?? '',
      password: json['password'] ?? '',
      wss: json['wss'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'extension': extension,
      'domain': domain,
      'password': password,
      'wss': wss,
    };
  }

  @override
  String toString() {
    return 'ExtensionDetails(name: $name, extension: $extension, domain: $domain, wss: $wss)';
  }
}