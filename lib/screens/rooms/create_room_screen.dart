import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  // TODO(FOODPOOL): 타이머 picker로 바꾸기(24시간제)
  final _hourCtrl = TextEditingController(text: '18');
  final _minuteCtrl = TextEditingController(text: '30');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _storeNameCtrl.dispose();
    _pickupCtrl.dispose();
    _linkCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // TODO(FOODPOOL):
    // 1) hour/minute -> 오늘 endAt(DateTime) 만들기
    // 2) RoomRepository.createRoom(...) 호출
    // 3) 생성된 roomId 받아서 상세로 이동
    //
    // 예:
    // final roomId = await context.read<RoomProvider>().createRoom(...);
    // if (!mounted) return;
    // context.go('/room/$roomId');

    // 임시: 생성 성공 가정하고 뒤로
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: 방 생성 로직 연결')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 12),
              const Text('마감 시간(오늘)'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hourCtrl,
                      decoration: const InputDecoration(labelText: '시(00~23)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 23) return '0~23';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minuteCtrl,
                      decoration: const InputDecoration(labelText: '분(00~59)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0 || n > 59) return '0~59';
                        return null;
                      },
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
