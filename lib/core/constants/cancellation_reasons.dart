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
