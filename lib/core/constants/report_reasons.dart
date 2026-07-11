class ReportReasonOption {
  final String code;
  final String label;

  const ReportReasonOption(this.code, this.label);
}

const List<ReportReasonOption> kClientReportReasons = [
  ReportReasonOption('report.client.worker_no_show', 'Nhân viên không đến'),
  ReportReasonOption('report.client.worker_rude', 'Nhân viên có thái độ không tốt'),
  ReportReasonOption('report.client.worker_poor_quality', 'Chất lượng dịch vụ kém'),
  ReportReasonOption('report.client.other', 'Lý do khác'),
];

const List<ReportReasonOption> kWorkerReportReasons = [
  ReportReasonOption('report.worker.client_absent', 'Khách hàng vắng mặt'),
  ReportReasonOption('report.worker.unsafe_environment', 'Môi trường làm việc không an toàn'),
  ReportReasonOption('report.worker.client_abusive', 'Khách hàng có hành vi không đúng mực'),
  ReportReasonOption('report.worker.other', 'Lý do khác'),
];

const int kReportMinFreeTextLength = 20;
