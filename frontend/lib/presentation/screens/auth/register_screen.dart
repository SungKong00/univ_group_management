import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/models/group_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_button.dart';
import '../../widgets/common_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/otp6_input.dart';

const String kNicknamePattern = r'^[a-zA-Z0-9가-힣]{2,16}$';
final RegExp kNicknameRegExp = RegExp(kNicknamePattern);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _studentNo = TextEditingController();
  final _schoolEmail = TextEditingController();
  String _role = 'STUDENT';

  // College/Dept state
  GroupHierarchyNode? _selectedCollege;
  GroupHierarchyNode? _selectedDepartment;
  List<GroupHierarchyNode> _departmentsOfSelectedCollege = [];

  // Nickname validation state
  bool _checkingNickname = false;
  bool? _nicknameAvailable;
  List<String> _nicknameSuggestions = const [];
  String? _nicknameHint;
  Timer? _debounce;

  // OTP state
  bool _otpSent = false;
  bool _otpVerifying = false;
  bool _otpVerified = false;
  int _otpSecondsLeft = 300;
  int _resendCooldown = 0;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupHierarchy();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _studentNo.dispose();
    _schoolEmail.dispose();
    _debounce?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _onNicknameChanged(String value) {
    setState(() {
      _nicknameAvailable = null;
      _nicknameSuggestions = const [];
      _nicknameHint = null;
      _checkingNickname = true;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final nick = value.trim();
      if (nick.length < 2) {
        setState(() {
          _checkingNickname = false;
          _nicknameAvailable = false;
          _nicknameHint = '닉네임은 2자 이상이어야 합니다';
        });
        return;
      }
      if (!kNicknameRegExp.hasMatch(nick)) {
        setState(() {
          _checkingNickname = false;
          _nicknameAvailable = false;
          _nicknameHint = '2-16자, 영문/숫자/한글만 가능해요';
        });
        return;
      }
      final result = await context.read<AuthProvider>().checkNickname(nick);
      if (!mounted) return;
      setState(() {
        _checkingNickname = false;
        if (result == null) {
          _nicknameAvailable = null;
          _nicknameHint = '검증 중 오류가 발생했습니다';
        } else {
          _nicknameAvailable = result.available;
          _nicknameSuggestions = result.suggestions;
          _nicknameHint = result.available ? '사용 가능한 닉네임이에요' : '이미 사용 중인 닉네임입니다';
        }
      });
    });
  }

  bool _canSendCode() {
    final email = _schoolEmail.text.trim();
    final valid = email.isNotEmpty && email.contains('@') && email.endsWith('.ac.kr');
    if (!valid) return false;
    if (_otpSent && _resendCooldown > 0) return false;
    return true;
  }

  void _onSendCodePressed(BuildContext context) async {
    final email = _schoolEmail.text.trim();
    setState(() {
      _otpSent = true;
      _otpVerified = AppConstants.mockEmailVerification ? true : false;
      _otpSecondsLeft = 300;
      _resendCooldown = 30;
    });
    _startOtpTimer();
    _startResendCooldown();
    final ok = await context.read<AuthProvider>().sendEmailOtp(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '인증 코드를 보냈어요' : '코드 전송에 실패했어요')),
      );
    }
  }

  void _startOtpTimer() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _otpSecondsLeft <= 0 || _otpVerified) return t.cancel();
      setState(() => _otpSecondsLeft -= 1);
    });
  }

  void _startResendCooldown() {
    if (_resendCooldown <= 0) return;
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendCooldown <= 0) return t.cancel();
      setState(() => _resendCooldown -= 1);
    });
  }

  Future<void> _onOtpChanged(BuildContext context, String value) async {
    if (value.length != 6 || _otpVerifying || _otpVerified) return;
    setState(() => _otpVerifying = true);
    final ok = await context.read<AuthProvider>().verifyEmailOtp(_schoolEmail.text.trim(), value);
    if (!mounted) return;
    setState(() {
      _otpVerifying = false;
      if (ok) _otpVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '인증이 완료되었어요' : '코드가 일치하지 않아요')),
    );
  }

  Widget _buildTimerAndResend(BuildContext context) {
    final mm = (_otpSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_otpSecondsLeft % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$mm:$ss', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 8),
        TextButton(
          onPressed: (_resendCooldown > 0 || !_canSendCode()) ? null : () => _onSendCodePressed(context),
          child: Text(_resendCooldown > 0 ? '재전송($_resendCooldown)' : '재전송'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (AppConstants.requireEmailOtp && !_otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이메일 인증을 완료해주세요.')));
      return;
    }
    final ok = await context.read<AuthProvider>().submitOnboarding(
          OnboardingRequest(
            name: _name.text.trim(),
            nickname: _nickname.text.trim(),
            college: _selectedCollege?.name,
            dept: _selectedDepartment?.name,
            studentNo: _studentNo.text.trim().isEmpty ? null : _studentNo.text.trim(),
            schoolEmail: _schoolEmail.text.trim(),
            role: _role,
          ),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('온보딩')),
      body: Consumer2<AuthProvider, GroupProvider>(
        builder: (context, auth, groups, _) {
          final colleges = groups.hierarchy.where((g) => g.type == GroupType.college).toList();

          return LoadingOverlay(
            isLoading: auth.isLoading || (groups.isLoading && groups.hierarchy.isEmpty),
            message: auth.isLoading ? '제출 중...' : '그룹 정보 로딩 중...',
            child: SafeArea(
              child: Padding(
                padding: AppStyles.paddingL,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('기본 정보를 입력해주세요', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 24),
                            CommonTextField(label: '이름', hint: '실명', controller: _name, prefixIcon: Icons.person_outline, validator: (v) => (v == null || v.trim().length < 2) ? '이름을 입력해주세요' : null),
                            const SizedBox(height: 16),
                            CommonTextField(
                              label: '닉네임',
                              hint: '표시 이름',
                              controller: _nickname,
                              prefixIcon: Icons.alternate_email,
                              onChanged: _onNicknameChanged,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return '닉네임을 입력해주세요';
                                if (!kNicknameRegExp.hasMatch(v.trim())) return '2-16자, 영문/숫자/한글만 가능해요';
                                if (_nicknameAvailable == false) return '이미 사용 중인 닉네임입니다';
                                return null;
                              },
                              suffix: _checkingNickname ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))) : (_nicknameAvailable == true ? const Icon(Icons.check_circle, color: Colors.green) : (_nicknameAvailable == false ? const Icon(Icons.error, color: Colors.red) : null)),
                            ),
                            if (_nicknameHint != null) ...[const SizedBox(height: 8), Text(_nicknameHint!, style: TextStyle(color: _nicknameAvailable == false ? Colors.red : _nicknameAvailable == true ? Colors.green : AppTheme.textSecondaryColor))],
                            if (_nicknameSuggestions.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: _nicknameSuggestions.take(5).map((s) => ActionChip(label: Text(s), onPressed: () { _nickname.text = s; _onNicknameChanged(s); })).toList())],
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('계열', style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<GroupHierarchyNode>(
                                  value: _selectedCollege,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.school_outlined),
                                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  ),
                                  items: colleges
                                      .map((college) => DropdownMenuItem<GroupHierarchyNode>(
                                            value: college,
                                            child: Text(college.name),
                                          ))
                                      .toList(),
                                  onChanged: (college) {
                                    setState(() {
                                      _selectedCollege = college;
                                      _selectedDepartment = null;
                                      _departmentsOfSelectedCollege = college != null
                                          ? groups.hierarchy
                                              .where((g) => g.type == GroupType.department && g.parentId == college.id)
                                              .toList()
                                          : [];
                                    });
                                  },
                                  validator: (v) => v == null ? '계열을 선택해주세요' : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('학과 (선택)', style: Theme.of(context).textTheme.titleSmall),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<GroupHierarchyNode?>(
                                        value: _selectedDepartment,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.school_outlined),
                                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                        ),
                                        items: [
                                          const DropdownMenuItem<GroupHierarchyNode?>(value: null, child: Text('선택 안함')),
                                          ..._departmentsOfSelectedCollege.map(
                                            (dept) => DropdownMenuItem<GroupHierarchyNode?>(value: dept, child: Text(dept.name)),
                                          )
                                        ],
                                        onChanged: _selectedCollege == null ? null : (dept) => setState(() => _selectedDepartment = dept),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CommonTextField(
                                    label: '학번 (선택)',
                                    hint: '예: 20201234',
                                    controller: _studentNo,
                                    prefixIcon: Icons.badge_outlined,
                                    labelTextStyle: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('어떤 역할로 시작하시겠어요?', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(segments: const [ButtonSegment(value: 'STUDENT', label: Text('학생'), icon: Icon(Icons.school_outlined)), ButtonSegment(value: 'PROFESSOR', label: Text('교수'), icon: Icon(Icons.person_outline))], selected: {_role}, onSelectionChanged: (sel) => setState(() => _role = sel.first)),
                            if (_role == 'PROFESSOR') ...[const SizedBox(height: 8), Row(children: const [Icon(Icons.info_outline, size: 16, color: Colors.black54), SizedBox(width: 6), Expanded(child: Text('교수 권한은 승인 후 활성화돼요', style: TextStyle(color: Colors.black54)))])],
                            const SizedBox(height: 16),
                            CommonTextField(label: '학교 이메일', hint: '예: user@hs.ac.kr', controller: _schoolEmail, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined, validator: (v) => (v == null || v.trim().isEmpty || !v.contains('@') || !v.endsWith('.ac.kr')) ? '학교 이메일 형식이 아닙니다' : null, suffix: TextButton(onPressed: _canSendCode() ? () => _onSendCodePressed(context) : null, child: const Text('인증 코드 받기'))),
                            if (_otpSent || _otpVerified || AppConstants.requireEmailOtp) ...[const SizedBox(height: 12), Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: IgnorePointer(ignoring: _otpVerified, child: Otp6Input(enabled: !_otpVerified, onCompleted: (code) => _onOtpChanged(context, code)))), const SizedBox(width: 12), if (_otpVerifying) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) else if (_otpVerified) const Icon(Icons.verified, color: Colors.green) else _buildTimerAndResend(context)])],
                            const SizedBox(height: 24),
                            if (auth.error != null) ...[Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.08), borderRadius: AppStyles.radiusM, border: Border.all(color: AppTheme.errorColor.withOpacity(0.3))), child: Text(auth.error!, style: const TextStyle(color: AppTheme.errorColor))), const SizedBox(height: 16)],
                            CommonButton(text: '제출', onPressed: (_nicknameAvailable == false || _checkingNickname || (AppConstants.requireEmailOtp && !_otpVerified)) ? null : _submit, height: 52),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
