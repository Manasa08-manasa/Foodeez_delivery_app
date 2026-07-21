import 'package:socket_io_client/socket_io_client.dart' as IO;

class WsDeliveryAssignment {
  final String assignmentId;
  final String orderId;
  final String? orderNumber;
  final double deliveryFee;
  final double? surgeMultiplier;
  final double? estimatedDistanceKm;
  final int? estimatedDurationMins;
  final DateTime? acceptDeadlineAt;
  final String? customerAddress;

  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double? customerLatitude;
  final double? customerLongitude;

  const WsDeliveryAssignment({
    required this.assignmentId,
    required this.orderId,
    this.orderNumber,
    required this.deliveryFee,
    this.surgeMultiplier,
    this.estimatedDistanceKm,
    this.estimatedDurationMins,
    this.acceptDeadlineAt,
    this.customerAddress,
    this.restaurantLatitude,
    this.restaurantLongitude,
    this.customerLatitude,
    this.customerLongitude,
  });

  factory WsDeliveryAssignment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString();
      return s.isEmpty ? null : double.tryParse(s);
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v.toString();
      return s.isEmpty ? null : int.tryParse(s);
    }

    return WsDeliveryAssignment(
      assignmentId: json['assignmentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString(),
      deliveryFee: (json['deliveryFee'] is num ? (json['deliveryFee'] as num).toDouble() : double.tryParse(json['deliveryFee']?.toString() ?? '0') ?? 0),
      surgeMultiplier: parseDouble(json['surgeMultiplier']),
      estimatedDistanceKm: parseDouble(json['estimatedDistanceKm']),
      estimatedDurationMins: parseInt(json['estimatedDurationMins']),
      acceptDeadlineAt: parseDate(json['acceptDeadlineAt']),
      customerAddress: json['customerAddress']?.toString(),
      restaurantLatitude: parseDouble(json['restaurantLatitude']),
      restaurantLongitude: parseDouble(json['restaurantLongitude']),
      customerLatitude: parseDouble(json['customerLatitude']),
      customerLongitude: parseDouble(json['customerLongitude']),
    );
  }
}

typedef NewAssignmentHandler = void Function(WsDeliveryAssignment assignment);
typedef AssignmentCancelledHandler = void Function(String assignmentId);

/// Socket.IO client for real-time delivery partner assignment notifications.
class DeliverySocketService {
  IO.Socket? _socket;

  bool get isConnected => _socket != null;

  void connect({
    required String partnerId,
    required NewAssignmentHandler onNewAssignment,
    required AssignmentCancelledHandler onAssignmentCancelled,
  }) {
    disconnect();

    _socket = IO.io(
      'https://int.foodeez.in/ws/delivery/orders/live',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..on('connect', (_) {
        _socket!.emit('join-partner-room', {'partnerId': partnerId});
      })
      ..on('new-assignment', (data) {
        if (data is Map<String, dynamic>) {
          final a = WsDeliveryAssignment.fromJson(data);
          if (a.assignmentId.isNotEmpty) onNewAssignment(a);
        } else if (data is Map) {
          onNewAssignment(WsDeliveryAssignment.fromJson(data.cast<String, dynamic>()));
        }
      })
      ..on('assignment-cancelled', (data) {
        if (data is Map && data['assignmentId'] != null) {
          onAssignmentCancelled(data['assignmentId'].toString());
        }
      });

    _socket!.connect();
  }

  void disconnect() {
    final s = _socket;
    _socket = null;
    if (s != null) {
      try {
        s.disconnect();
        s.dispose();
      } catch (_) {}
    }
  }
}

