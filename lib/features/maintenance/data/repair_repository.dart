import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repair_shop.dart';

final repairRepositoryProvider = Provider((ref) => RepairRepository());

class RepairRepository {
  Future<List<RepairShop>> fetchRepairShops() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const RepairShop(
        id: 1,
        name: '한일정밀 (Hanil Precision)',
        location: 'Ansan Industrial Complex',
        distanceKm: 2.5,
        rating: 4.8,
        reviewCount: 5,
        isPremium: true,
        specializations: [
          'High Voltage Motor',
          'Precision Alignment',
          'Bearing Replacement',
        ],
        equipment: [
          'Laser Alignment Tool',
          'Vibration Analyzer',
          'Thermal Camera',
        ],
        imageUrl: 'https://placehold.co/100x100/1a1a1a/ffffff?text=Hanil',
        reviews: [
          Review(
            userName: 'Kim M.S.',
            role: 'Production Mgr',
            rating: 5.0,
            date: '2 days ago',
            comment:
                '200HP 펌프 축 정렬(Alignment) 작업 맡겼는데, 진동값 4.5에서 0.3mm/s로 완벽하게 잡혔습니다. 레이저 장비 쓰셔서 그런지 확실하네요.',
          ),
          Review(
            userName: 'Lee S.J.',
            role: 'Maintenance',
            rating: 4.8,
            date: '1 week ago',
            comment:
                '새벽에 인버터 과열로 라인 설 뻔했는데 긴급출동(Urgent Dispatch) 덕분에 살았습니다. 스페어 파트도 바로 가지고 오셨네요.',
          ),
          Review(
            userName: 'Park D.H.',
            role: 'Engineer',
            rating: 4.5,
            date: '3 weeks ago',
            comment: '모터 베어링 교체 후 소음이 완전히 사라졌습니다. 다만 예약 잡기가 좀 힘드네요.',
          ),
          Review(
            userName: 'Choi Y.K.',
            role: 'Safety Officer',
            rating: 5.0,
            date: '1 month ago',
            comment: '절연 저항 불량으로 의뢰했는데, 권선 교체작업 깔끔하게 해주셨습니다. 레포트도 상세해서 좋았어요.',
          ),
          Review(
            userName: 'Jung H.S.',
            role: 'Facilities',
            rating: 4.7,
            date: '2 months ago',
            comment: '안산 공단 내에서 제일 실력 좋은 곳입니다. 긴급 대응이 빨라서 항상 믿고 맡깁니다.',
          ),
        ],
      ),
      const RepairShop(
        id: 2,
        name: '대성전기 (Daesung Electric)',
        location: 'Siheung Smart Hub',
        distanceKm: 1.8,
        rating: 4.5,
        reviewCount: 3,
        isPremium: false,
        specializations: [
          'AC/DC Motor Reward',
          'Pump Repair',
          'Bearing Replacement',
        ],
        equipment: ['Balancing Machine', 'VPI System'],
        imageUrl: 'https://placehold.co/100x100/1a1a1a/ffffff?text=Daesung',
        reviews: [
          Review(
            userName: 'Kang H.W.',
            role: 'Facility Mgr',
            rating: 5.0,
            date: '1 month ago',
            comment: '급한 모터 수리였는데 야간 작업으로 일정 맞춰주셔서 감사합니다. 베어링 소음도 확실히 잡혔네요.',
          ),
          Review(
            userName: 'Lim J.H.',
            role: 'Maintenance',
            rating: 4.2,
            date: '2 months ago',
            comment: '수리 품질은 좋은데 견적서 받는데 시간이 좀 걸렸습니다.',
          ),
          Review(
            userName: 'Song B.C.',
            role: '',
            rating: 4.5,
            date: '3 months ago',
            comment: '소형 펌프 수리는 대성전기가 제일 빠릅니다.',
          ),
        ],
      ),
      const RepairShop(
        id: 3,
        name: 'Global Tech Services',
        location: 'Incheon Namdong',
        distanceKm: 12.4,
        rating: 4.9,
        reviewCount: 2,
        isPremium: true,
        specializations: [
          'Predictive Maintenance',
          'Vibration Analysis',
          'Thermal Imaging',
        ],
        equipment: ['Online Monitoring System', 'Ultrasound Detector'],
        imageUrl: 'https://placehold.co/100x100/1a1a1a/ffffff?text=Global',
        reviews: [
          Review(
            userName: 'James Kim',
            role: 'Plant Mgr',
            rating: 5.0,
            date: '2 weeks ago',
            comment:
                'Excellent vibe analysis service. Diagnosed the unbalance issue correctly.',
          ),
          Review(
            userName: 'Oh S.M.',
            role: 'Reliability Eng',
            rating: 4.8,
            date: '1 month ago',
            comment: '열화상 진단 리포트 퀄리티가 매우 높습니다. 예방 정비에 큰 도움이 됩니다.',
          ),
        ],
      ),
      const RepairShop(
        id: 4,
        name: '성진모터 (Sungjin Motor)',
        location: 'Geumcheon-gu, Seoul',
        distanceKm: 8.2,
        rating: 4.2,
        reviewCount: 0,
        isPremium: false,
        specializations: ['Small Motor Repair', 'Fan/Blower'],
        equipment: ['Portable Balancer'],
        imageUrl: 'https://placehold.co/100x100/1a1a1a/ffffff?text=Sungjin',
        reviews: [],
      ),
      const RepairShop(
        id: 5,
        name: 'Future Drive Systems',
        location: 'Hwaseong Dongtan',
        distanceKm: 15.6,
        rating: 4.7,
        reviewCount: 0,
        isPremium: true,
        specializations: ['Inverter/VFD Repair', 'Servo Motor', 'PCB Repair'],
        equipment: ['Load Test Bench', 'Oscilloscope'],
        imageUrl: 'https://placehold.co/100x100/1a1a1a/ffffff?text=Future',
        reviews: [],
      ),
    ];
  }
}
