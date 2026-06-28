class Contact {
  const Contact({
    required this.id,
    required this.contactName,
    required this.phone,
    required this.address,
    required this.status,
    required this.contactType,
    required this.contactStatus,
    required this.note,
    required this.contactDate,
    required this.contactTime,
    required this.contactQuality,
    required this.contactNotification,
    required this.archivedAt,
  });

  final String id;
  final String contactName;
  final String phone;
  final String address;
  final String status;
  final String contactType;
  final String? contactStatus;
  final String note;
  final DateTime? contactDate;
  final String contactTime;
  final String contactQuality;
  final DateTime? contactNotification;
  final DateTime? archivedAt;

  Contact copyWith({
    String? contactName,
    String? phone,
    String? address,
    String? status,
    String? contactType,
    String? contactStatus,
    String? note,
    DateTime? contactDate,
    String? contactTime,
    String? contactQuality,
    DateTime? contactNotification,
    DateTime? archivedAt,
  }) {
    return Contact(
      id: id,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
      contactType: contactType ?? this.contactType,
      contactStatus: contactStatus ?? this.contactStatus,
      note: note ?? this.note,
      contactDate: contactDate ?? this.contactDate,
      contactTime: contactTime ?? this.contactTime,
      contactQuality: contactQuality ?? this.contactQuality,
      contactNotification: contactNotification ?? this.contactNotification,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  factory Contact.fromMap(Map<String, dynamic> data) {
    return Contact(
      id: data['id']?.toString() ?? '',
      contactName: data['contact_name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      status: _normalizeContactStatus(data['status']?.toString() ?? ''),
      contactType: data['contact_type']?.toString() ?? '',
      contactStatus: data['contact_status']?.toString(),
      note: data['note']?.toString() ?? '',
      contactDate: DateTime.tryParse(data['contact_date']?.toString() ?? ''),
      contactTime: data['contact_time']?.toString() ?? '',
      contactQuality: data['contact_quality']?.toString() ?? '',
      contactNotification: DateTime.tryParse(
        data['contact_notification']?.toString() ?? '',
      ),
      archivedAt: DateTime.tryParse(data['archived_at']?.toString() ?? ''),
    );
  }
}

class ContactEvent {
  const ContactEvent({
    required this.id,
    required this.contactId,
    required this.eventType,
    required this.eventNote,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String contactId;
  final String eventType;
  final String eventNote;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory ContactEvent.fromMap(Map<String, dynamic> data) {
    final rawMetadata = data['metadata'];
    return ContactEvent(
      id: data['id']?.toString() ?? '',
      contactId: data['contact_id']?.toString() ?? '',
      eventType: data['event_type']?.toString() ?? '',
      eventNote: data['event_note']?.toString() ?? '',
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata)
          : const {},
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
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
    'visit_required' || 'quick_contact' || 'to_visit' || 'to_call' => 'contact',
    'lead' => 'scheduled_meeting',
    'client' => 'scheduled_meeting',
    'lost' => 'not_interested',
    'scheduled_meeting' ||
    'interested' ||
    'contact' ||
    'postponed' ||
    'meeting_active' ||
    'meeting_done' ||
    'signed_contract' ||
    'not_interested' ||
    'no_contact' => status,
    _ => 'scheduled_meeting',
  };
}
