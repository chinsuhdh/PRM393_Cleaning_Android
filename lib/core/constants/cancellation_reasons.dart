class CancellationReasonOption {
  final String code;
  final String label;

  const CancellationReasonOption(this.code, this.label);
}

const String kWorkerCancelReasonOther = 'worker_cancel.other';

const List<CancellationReasonOption> kWorkerCancelReasons = [
  CancellationReasonOption('worker_cancel.schedule_conflict', 'Trùng lịch trình'),
  CancellationReasonOption('worker_cancel.too_far', 'Địa chỉ quá xa'),
  CancellationReasonOption(kWorkerCancelReasonOther, 'Lý do khác'),
];

const String kClientCancelReasonOther = 'client_cancel.other';

const List<CancellationReasonOption> kClientCancelReasons = [
  CancellationReasonOption('client_cancel.no_longer_needed', 'Không còn cần dịch vụ'),
  CancellationReasonOption('client_cancel.found_another_provider', 'Đã tìm được đơn vị khác'),
  CancellationReasonOption(kClientCancelReasonOther, 'Lý do khác'),
];
