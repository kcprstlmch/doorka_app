class Contact {
  const Contact({
    required this.id,
    required this.contactName,
    required this.phone,
    required this.address,
    required this.status,
    required this.note,
    required this.contactDate,
    required this.contactTime,
    required this.contactProduct,
    required this.contactQuality,
    required this.contactNotification,
  });

  final String id;
  final String contactName;
  final String phone;
  final String address;
  final String status;
  final String note;
  final DateTime? contactDate;
  final String contactTime;
  final String contactProduct;
  final String contactQuality;
  final DateTime? contactNotification;

  factory Contact.fromMap(Map<String, dynamic> data) {
    return Contact(
      id: data['id']?.toString() ?? '',
      contactName: data['contact_name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      status: _normalizeContactStatus(data['status']?.toString() ?? ''),
      note: data['note']?.toString() ?? '',
      contactDate: DateTime.tryParse(data['contact_date']?.toString() ?? ''),
      contactTime: data['contact_time']?.toString() ?? '',
      contactProduct: data['contact_product']?.toString() ?? '',
      contactQuality: data['contact_quality']?.toString() ?? '',
      contactNotification: DateTime.tryParse(
        data['contact_notification']?.toString() ?? '',
      ),
    );
  }
}

class Client {
  const Client({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.correspondenceAddress,
    required this.installationAddress,
    required this.productName,
    required this.executionMethod,
    required this.status,
    required this.contractSignedAt,
    required this.sourceContactId,
  });

  final String id;
  final String sourceContactId;
  final String clientName;
  final String phone;
  final String correspondenceAddress;
  final String installationAddress;
  final String productName;
  final String executionMethod;
  final String status;
  final DateTime? contractSignedAt;

  Client copyWith({
    String? clientName,
    String? phone,
    String? correspondenceAddress,
    String? installationAddress,
    String? productName,
    String? executionMethod,
    String? status,
  }) {
    return Client(
      id: id,
      sourceContactId: sourceContactId,
      clientName: clientName ?? this.clientName,
      phone: phone ?? this.phone,
      correspondenceAddress:
          correspondenceAddress ?? this.correspondenceAddress,
      installationAddress: installationAddress ?? this.installationAddress,
      productName: productName ?? this.productName,
      executionMethod: executionMethod ?? this.executionMethod,
      status: status ?? this.status,
      contractSignedAt: contractSignedAt,
    );
  }

  factory Client.fromMap(Map<String, dynamic> data) {
    final rawExecutionMethod =
        (data['execution_method'] ?? data['payment_method'])?.toString() ?? '';

    return Client(
      id: data['id']?.toString() ?? '',
      sourceContactId: data['source_contact_id']?.toString() ?? '',
      clientName: data['client_name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      correspondenceAddress: data['correspondence_address']?.toString() ?? '',
      installationAddress: data['installation_address']?.toString() ?? '',
      productName: data['product_name']?.toString() ?? '',
      executionMethod: normalizeExecutionMethod(rawExecutionMethod),
      status: data['status']?.toString() ?? 'signed_contract',
      contractSignedAt: DateTime.tryParse(
        data['contract_signed_at']?.toString() ?? '',
      ),
    );
  }
}

String normalizeExecutionMethod(String method) {
  return switch (method) {
    'gotowka' || 'cash' => 'gotowka',
    'finansowanie' || 'credit' || 'kredyt' || 'raty' => 'finansowanie',
    _ => 'finansowanie',
  };
}

String _normalizeContactStatus(String status) {
  return switch (status) {
    'signed_contract' => 'scheduled_meeting',
    'visit_required' => 'to_visit',
    'contact' => 'to_call',
    'lead' => 'scheduled_meeting',
    'client' => 'scheduled_meeting',
    'lost' => 'not_interested',
    'scheduled_meeting' ||
    'interested' ||
    'quick_contact' ||
    'to_visit' ||
    'to_call' ||
    'not_interested' ||
    'no_contact' => status,
    _ => 'scheduled_meeting',
  };
}
