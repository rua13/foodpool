import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';
import '../../providers/order_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  final _depositMethodsCtrl = TextEditingController();
  final _minOrderAmountCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();

  int? _selectedHour;
  int? _selectedMinute;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _storeNameCtrl.dispose();
    _pickupCtrl.dispose();
    _linkCtrl.dispose();
    _depositMethodsCtrl.dispose();
    _minOrderAmountCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    super.dispose();
  }

  DateTime _buildEndAtLocal({
    required int hour,
    required int minute,
  }) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  List<int> _allowedHours() {
    final now = DateTime.now();
    // "오늘" + "지금 이후만 선택" => 현재 시보다 작은 시는 제거
    // 같은 시는 minute에서 필터링
    return List<int>.generate(24, (i) => i).where((h) => h >= now.hour).toList();
  }

  List<int> _allowedMinutesForHour(int hour) {
    final now = DateTime.now();
    //  1분 단위
    final minutes = List<int>.generate(60, (i) => i * 1);

    if (hour > now.hour) return minutes;

    // hour == now.hour: 현재 분 이후만
    return minutes.where((m) => m > now.minute).toList();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHour == null || _selectedMinute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마감 시간을 선택해주세요.')),
      );
      return;
    }

    final endAt = _buildEndAtLocal(hour: _selectedHour!, minute: _selectedMinute!);
    final now = DateTime.now();
    if (!endAt.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마감 시간은 현재 시간 이후만 가능해요.')),
      );
      return;
    }

    final minOrderAmount = int.parse(_minOrderAmountCtrl.text.trim());
    final deliveryFee = int.parse(_deliveryFeeCtrl.text.trim());

    final auth = context.read<AppAuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      await context.read<OrderProvider>().createOrder(
        ownerId: uid,
        title: _titleCtrl.text.trim(),
        storeName: _storeNameCtrl.text.trim(),
        pickupSpot: _pickupCtrl.text.trim(),
        link: _linkCtrl.text.trim(),
        depositMethods: _depositMethodsCtrl.text.trim(),
        minimumOrderAmount: minOrderAmount,
        deliveryFee: deliveryFee,
        endAtLocal: endAt,
      );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _allowedHours();

    // 초기값 자동 세팅(화면 처음 열었을 때)
    _selectedHour ??= hours.isNotEmpty ? hours.first : null;
    final minutes =
        _selectedHour == null ? <int>[] : _allowedMinutesForHour(_selectedHour!);
    _selectedMinute ??= minutes.isNotEmpty ? minutes.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('공동주문 만들기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '메뉴 이름(제목)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '필수 항목' : null,
              ),
              TextFormField(
                controller: _storeNameCtrl,
                decoration: const InputDecoration(labelText: '가게명'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '필수 항목' : null,
              ),
              TextFormField(
                controller: _pickupCtrl,
                decoration: const InputDecoration(labelText: '수령 장소'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '필수 항목' : null,
              ),
              TextFormField(
                controller: _linkCtrl,
                decoration: const InputDecoration(labelText: '주문 링크'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '필수 항목' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _depositMethodsCtrl,
                decoration: const InputDecoration(labelText: '입금 방법 (예: 토스/계좌이체)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '필수 항목' : null,
              ),
              TextFormField(
                controller: _minOrderAmountCtrl,
                decoration: const InputDecoration(labelText: '최소 주문 금액(원)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return '숫자만 입력';
                  if (n < 0) return '0 이상';
                  return null;
                },
              ),
              TextFormField(
                controller: _deliveryFeeCtrl,
                decoration: const InputDecoration(labelText: '배달비(원)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return '숫자만 입력';
                  if (n < 0) return '0 이상';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text('마감 시간(오늘, 현재시간 이후만 선택 가능)'),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedHour,
                      decoration: const InputDecoration(labelText: '시'),
                      items: hours
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text(_two(h)),
                              ))
                          .toList(),
                      onChanged: (h) {
                        if (h == null) return;
                        setState(() {
                          _selectedHour = h;
                          final mins = _allowedMinutesForHour(h);
                          _selectedMinute = mins.isNotEmpty ? mins.first : null;
                        });
                      },
                      validator: (v) => v == null ? '필수' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMinute,
                      decoration: const InputDecoration(labelText: '분'),
                      items: minutes
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_two(m)),
                              ))
                          .toList(),
                      onChanged: (m) {
                        setState(() => _selectedMinute = m);
                      },
                      validator: (v) => v == null ? '필수' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('생성하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
