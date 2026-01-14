enum RepairStatus {
  pending('Pending', '확인 중'),
  quoted('Quoted', '견적 발송'),
  scheduled('Scheduled', '방문 예정'),
  completed('Completed', '수리 완료');

  final String label;
  final String labelKo;

  const RepairStatus(this.label, this.labelKo);
}
