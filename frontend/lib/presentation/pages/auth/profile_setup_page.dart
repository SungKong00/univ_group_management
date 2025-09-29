import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/models/group_models.dart';
import '../../../core/models/user_models.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/buttons/primary_button.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final AuthService _authService = AuthService();
  final OnboardingService _onboardingService = OnboardingService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _studentNumberController = TextEditingController();
  final TextEditingController _schoolEmailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isInitializing = true;
  bool _isSubmitting = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _emailVerified = true; // 임시로 인증 완료 상태로 설정
  String? _initializationError;

  NicknameStatus _nicknameStatus = NicknameStatus.initial;
  List<String> _nicknameSuggestions = const [];
  Timer? _nicknameDebounce;
  String? _nicknameErrorMessage;

  Set<SignupRole> _selectedRole = {SignupRole.student};

  final Map<int, GroupHierarchyNode> _nodesById = <int, GroupHierarchyNode>{};
  final List<GroupHierarchyNode> _colleges = <GroupHierarchyNode>[];
  final Map<int, List<GroupHierarchyNode>> _departmentsByCollege =
      <int, List<GroupHierarchyNode>>{};
  int? _selectedCollegeId;
  int? _selectedDepartmentId;

  Duration? _otpRemaining;
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _nicknameController.addListener(() {
      _onNicknameChanged(_nicknameController.text);
    });
  }

  @override
  void dispose() {
    _nicknameDebounce?.cancel();
    _otpTimer?.cancel();
    _nameController.dispose();
    _nicknameController.dispose();
    _studentNumberController.dispose();
    _schoolEmailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    if (mounted && !_isInitializing) {
      setState(() {
        _isInitializing = true;
        _initializationError = null;
      });
    }

    final user = _authService.currentUser;
    if (user != null) {
      _prefillFromUser(user);
    }

    try {
      final hierarchy = await _onboardingService.fetchGroupHierarchy();
      _processHierarchy(hierarchy);
      if (user != null) {
        _prefillSelectionsFromUser(user);
        // 임시로 이메일 인증을 완료된 것으로 처리
        _emailVerified = true;
        // 기본 학교 이메일 설정 (사용자 이메일이 없는 경우)
        if (_schoolEmailController.text.isEmpty) {
          _schoolEmailController.text = user.email.replaceAll('@gmail.com', '@example.ac.kr');
        }
      } else {
        // 사용자 정보가 없어도 임시로 인증 완료 처리
        _emailVerified = true;
        if (_schoolEmailController.text.isEmpty) {
          _schoolEmailController.text = 'user@example.ac.kr';
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _initializationError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _initializationError = _cleanMessage(e);
      });
    }
  }

  void _prefillFromUser(UserInfo user) {
    _nameController.text = user.name;
    if (user.nickname != null && user.nickname!.isNotEmpty) {
      _nicknameController.text = user.nickname!;
      _nicknameStatus = NicknameStatus.available;
    }
    if (user.studentNo != null) {
      _studentNumberController.text = user.studentNo!;
    }
    if (user.schoolEmail != null) {
      _schoolEmailController.text = user.schoolEmail!;
    }

    if (user.globalRole.toUpperCase() == SignupRole.professor.apiValue) {
      _selectedRole = {SignupRole.professor};
    } else {
      _selectedRole = {SignupRole.student};
    }
  }

  void _prefillSelectionsFromUser(UserInfo user) {
    if (_nodesById.isEmpty) {
      return;
    }

    if (user.department != null) {
      for (final entry in _nodesById.entries) {
        final node = entry.value;
        if (node.type == GroupNodeType.department && node.name == user.department) {
          _selectedDepartmentId = entry.key;
          _selectedCollegeId = node.parentId;
          break;
        }
      }
    }
  }

  void _processHierarchy(List<GroupHierarchyNode> nodes) {
    _nodesById.clear();
    _colleges.clear();
    _departmentsByCollege.clear();

    for (final node in nodes) {
      _nodesById[node.id] = node;
      if (node.type == GroupNodeType.college) {
        _colleges.add(node);
      } else if (node.type == GroupNodeType.department && node.parentId != null) {
        final list =
            _departmentsByCollege.putIfAbsent(node.parentId!, () => <GroupHierarchyNode>[]);
        list.add(node);
      }
    }

    _colleges.sort((a, b) => a.name.compareTo(b.name));
    for (final entry in _departmentsByCollege.entries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
    }
  }


  void _onNicknameChanged(String value) {
    _nicknameDebounce?.cancel();
    _nicknameSuggestions = const [];

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _nicknameStatus = NicknameStatus.initial;
        _nicknameErrorMessage = null;
      });
      return;
    }

    final validation = _validateNickname(trimmed);
    if (!validation.isValid) {
      setState(() {
        _nicknameStatus = NicknameStatus.invalid;
        _nicknameErrorMessage = validation.message;
      });
      return;
    }

    setState(() {
      _nicknameStatus = NicknameStatus.checking;
      _nicknameErrorMessage = null;
    });

    _nicknameDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final result = await _onboardingService.checkNickname(trimmed);
        if (!mounted) {
          return;
        }
        setState(() {
          _nicknameStatus =
              result.available ? NicknameStatus.available : NicknameStatus.unavailable;
          _nicknameSuggestions = result.suggestions;
          _nicknameErrorMessage = result.available
              ? null
              : '이미 사용 중인 닉네임입니다. 아래 추천 닉네임을 확인해보세요.';
        });
      } catch (e) {
        if (!mounted) {
          return;
        }
        setState(() {
          _nicknameStatus = NicknameStatus.invalid;
          _nicknameErrorMessage = _cleanMessage(e);
        });
      }
    });
  }

  NicknameValidationResult _validateNickname(String nickname) {
    if (nickname.length < 2) {
      return NicknameValidationResult(false, '닉네임은 2자 이상 입력해주세요.');
    }

    final regex = RegExp(r'^[a-zA-Z0-9가-힣]+$');
    if (!regex.hasMatch(nickname)) {
      return NicknameValidationResult(false, '한글, 영문, 숫자만 사용할 수 있어요.');
    }

    return const NicknameValidationResult(true, null);
  }

  Future<void> _sendOtp() async {
    final email = _schoolEmailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() {
        _emailVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _emailVerified = false;
    });

    try {
      await _onboardingService.sendEmailVerification(EmailSendRequest(email: email));
      if (!mounted) {
        return;
      }
      _startOtpCountdown();
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증 코드를 발송했어요. 5분 안에 입력해주세요.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_cleanMessage(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final email = _schoolEmailController.text.trim();
    final code = _otpController.text.trim();

    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('6자리 인증 코드를 정확히 입력해주세요.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      await _onboardingService.verifyEmailCode(
        EmailVerifyRequest(email: email, code: code),
      );
      if (!mounted) {
        return;
      }
      _otpTimer?.cancel();
      setState(() {
        _emailVerified = true;
        _otpRemaining = null;
      });
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증이 완료되었어요.')),
      );
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_cleanMessage(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  void _startOtpCountdown() {
    _otpTimer?.cancel();
    setState(() {
      _otpRemaining = const Duration(minutes: 5);
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_otpRemaining == null) {
          timer.cancel();
          return;
        }

        final secondsLeft = _otpRemaining!.inSeconds - 1;
        if (secondsLeft <= 0) {
          _otpRemaining = Duration.zero;
          timer.cancel();
        } else {
          _otpRemaining = Duration(seconds: secondsLeft);
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    if (_nicknameStatus != NicknameStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용 가능한 닉네임을 확인해주세요.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // 임시로 이메일 인증 조건 비활성화 (개발용)
    // if (!_emailVerified) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('학교 이메일 인증을 완료해주세요.'),
    //       backgroundColor: AppTheme.error,
    //     ),
    //   );
    //   return;
    // }

    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();
    final studentNo = _studentNumberController.text.trim();
    final email = _schoolEmailController.text.trim();

    final collegeName = _selectedCollegeId != null
        ? _nodesById[_selectedCollegeId!]?.name
        : null;
    final departmentName = _selectedDepartmentId != null
        ? _nodesById[_selectedDepartmentId!]?.name
        : null;

    final request = SignupProfileRequest(
      name: name,
      nickname: nickname,
      role: _selectedRole.first,
      schoolEmail: email,
      college: collegeName,
      department: departmentName,
      studentNo: studentNo.isEmpty ? null : studentNo,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedUser = await _onboardingService.submitSignupProfile(request);
      await _authService.updateCurrentUser(updatedUser);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 설정이 완료되었어요.')),
      );
      context.go(AppConstants.homeRoute);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_cleanMessage(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isWide = screenWidth >= 768;
    final isNarrow = screenWidth < 480;

    final horizontalPadding = isWide
        ? AppTheme.spacing32
        : isNarrow
            ? AppTheme.spacing12
            : AppTheme.spacing16;
    final verticalPadding = isWide
        ? AppTheme.spacing120
        : isNarrow
            ? AppTheme.spacing48
            : AppTheme.spacing96;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? AppTheme.spacing16 : AppTheme.spacing32,
                    vertical: isNarrow ? AppTheme.spacing24 : AppTheme.spacing32,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_initializationError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeadline(),
          const SizedBox(height: AppTheme.spacing24),
          _buildIntroCopy(),
          const SizedBox(height: AppTheme.spacing32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '계열/학과 정보를 불러오지 못했어요.',
                  style: AppTheme.headlineSmall.copyWith(color: AppTheme.error),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  _initializationError!,
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray700),
                ),
                const SizedBox(height: AppTheme.spacing16),
                PrimaryButton(
                  text: '다시 시도',
                  onPressed: _initializePage,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeadline(),
          const SizedBox(height: AppTheme.spacing12),
          _buildIntroCopy(),
          const SizedBox(height: AppTheme.spacing32),
          _buildNameField(),
          const SizedBox(height: AppTheme.spacing24),
          _buildNicknameField(),
          const SizedBox(height: AppTheme.spacing24),
          _buildAffiliationSelectors(),
          const SizedBox(height: AppTheme.spacing24),
          _buildStudentNumberField(),
          const SizedBox(height: AppTheme.spacing24),
          _buildRoleSelector(),
          const SizedBox(height: AppTheme.spacing24),
          _buildEmailVerificationFields(),
          const SizedBox(height: AppTheme.spacing32),
          PrimaryButton(
            text: '완료',
            onPressed: _isSubmitting ? null : _submit,
            isLoading: _isSubmitting,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      '기본 정보를 입력해주세요',
      style: AppTheme.displaySmall,
    );
  }

  Widget _buildIntroCopy() {
    return Text(
      '몇 가지 정보만 입력하면 바로 학과 워크스페이스를 이용할 수 있어요.',
      style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray600),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이름', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing12),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: '실명',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '이름을 입력해주세요.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNicknameField() {
    final helperColor = switch (_nicknameStatus) {
      NicknameStatus.available => AppTheme.success,
      NicknameStatus.unavailable => AppTheme.error,
      NicknameStatus.invalid => AppTheme.error,
      NicknameStatus.checking => AppTheme.gray600,
      NicknameStatus.initial => AppTheme.gray500,
    };

    final helperText = switch (_nicknameStatus) {
      NicknameStatus.available => '사용 가능한 닉네임이에요.',
      NicknameStatus.unavailable =>
          _nicknameErrorMessage ?? '이미 사용 중인 닉네임입니다.',
      NicknameStatus.invalid => _nicknameErrorMessage ?? '닉네임을 확인해주세요.',
      NicknameStatus.checking => '닉네임 중복을 확인하는 중...',
      NicknameStatus.initial => '다른 사용자에게 표시될 이름이에요.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('닉네임', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing12),
        TextFormField(
          controller: _nicknameController,
          textInputAction: TextInputAction.next,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '다른 사용자에게 표시될 이름',
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '닉네임을 입력해주세요.';
            }
            final validation = _validateNickname(value.trim());
            if (!validation.isValid) {
              return validation.message;
            }
            if (_nicknameStatus == NicknameStatus.unavailable) {
              return '다른 닉네임을 선택해주세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          children: [
            if (_nicknameStatus == NicknameStatus.checking)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (_nicknameStatus == NicknameStatus.checking)
              const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                helperText,
                style: AppTheme.bodySmall.copyWith(color: helperColor),
              ),
            ),
          ],
        ),
        if (_nicknameStatus == NicknameStatus.unavailable &&
            _nicknameSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing12),
            child: Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: _nicknameSuggestions
                  .map(
                    (suggestion) => ChoiceChip(
                      label: Text(suggestion),
                      selected: false,
                      onSelected: (_) {
                        _nicknameController.text = suggestion;
                        _nicknameController.selection = TextSelection.fromPosition(
                          TextPosition(offset: suggestion.length),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAffiliationSelectors() {
    final departmentOptions = _selectedCollegeId != null
        ? _departmentsByCollege[_selectedCollegeId!] ?? const []
        : const <GroupHierarchyNode>[];

    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('계열, 학과', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing12),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedCollegeId,
                      items: _colleges
                          .map(
                            (node) => DropdownMenuItem<int>(
                              value: node.id,
                              child: Text(node.name),
                            ),
                          )
                          .toList(),
                      decoration: const InputDecoration(
                        hintText: '계열(단과대) 선택 *필수',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return '계열을 선택해주세요.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCollegeId = value;
                          _selectedDepartmentId = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: departmentOptions.any((node) => node.id == _selectedDepartmentId)
                          ? _selectedDepartmentId
                          : null,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('선택 안함'),
                        ),
                        ...departmentOptions
                            .map(
                              (node) => DropdownMenuItem<int?>(
                                value: node.id,
                                child: Text(node.name),
                              ),
                            ),
                      ],
                      decoration: const InputDecoration(
                        hintText: '학과 선택 (선택사항)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCollegeId,
                    items: _colleges
                        .map(
                          (node) => DropdownMenuItem<int>(
                            value: node.id,
                            child: Text(node.name),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      hintText: '계열(단과대) 선택 *필수',
                    ),
                    validator: (value) {
                      if (value == null) {
                        return '계열을 선택해주세요.';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _selectedCollegeId = value;
                        _selectedDepartmentId = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  DropdownButtonFormField<int?>(
                    initialValue: departmentOptions.any((node) => node.id == _selectedDepartmentId)
                        ? _selectedDepartmentId
                        : null,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('선택 안함'),
                      ),
                      ...departmentOptions
                          .map(
                            (node) => DropdownMenuItem<int?>(
                              value: node.id,
                              child: Text(node.name),
                            ),
                          ),
                    ],
                    decoration: const InputDecoration(
                      hintText: '학과 선택 (선택사항)',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartmentId = value;
                      });
                    },
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildStudentNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('학번 (선택)', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing12),
        TextFormField(
          controller: _studentNumberController,
          decoration: const InputDecoration(
            hintText: '예: 20251234',
          ),
          keyboardType: TextInputType.number,
          maxLength: 10,
          buildCounter: (_, {required currentLength, maxLength, required isFocused}) {
            return const SizedBox.shrink();
          },
          validator: (value) {
            final trimmed = value?.trim();
            if (trimmed == null || trimmed.isEmpty) {
              return null;
            }
            if (trimmed.length < 4 || trimmed.length > 10) {
              return '학번은 4~10자리 숫자로 입력해주세요.';
            }
            if (int.tryParse(trimmed) == null) {
              return '숫자만 입력할 수 있어요.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final selectedRole = _selectedRole.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('어떤 역할로 시작하시겠어요?', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing12),
        SegmentedButton<SignupRole>(
          segments: const <ButtonSegment<SignupRole>>[
            ButtonSegment<SignupRole>(
              value: SignupRole.student,
              label: Text('학생'),
            ),
            ButtonSegment<SignupRole>(
              value: SignupRole.professor,
              label: Text('교수'),
            ),
          ],
          selected: _selectedRole,
          onSelectionChanged: (value) {
            setState(() {
              _selectedRole = value;
            });
          },
        ),
        if (selectedRole == SignupRole.professor)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing12),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.brandPrimary,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      '교수 권한은 관리자 승인 후 활성화돼요.',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.gray700),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailVerificationFields() {
    final email = _schoolEmailController.text.trim();
    final emailHint = email.isEmpty ? '학교 이메일 (예: student@hanshin.ac.kr)' : email;
    final mediaQuery = MediaQuery.of(context);
    final isNarrow = mediaQuery.size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('학교 이메일 인증', style: AppTheme.titleLarge),
        const SizedBox(height: AppTheme.spacing12),
        isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _schoolEmailController,
                    enabled: !_emailVerified,
                    decoration: InputDecoration(
                      hintText: emailHint,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _validateEmail(value?.trim() ?? ''),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _emailVerified || _isSendingOtp ? null : _sendOtp,
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_otpRemaining == null ? '인증 코드 받기' : '재전송'),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _schoolEmailController,
                      enabled: !_emailVerified,
                      decoration: InputDecoration(
                        hintText: emailHint,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateEmail(value?.trim() ?? ''),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 120,
                      maxWidth: 160,
                    ),
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _emailVerified || _isSendingOtp ? null : _sendOtp,
                        child: _isSendingOtp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_otpRemaining == null ? '인증 코드 받기' : '재전송',
                                  style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
        if (_emailVerified)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppTheme.success,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '인증이 완료되었어요.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.success),
                ),
              ],
            ),
          )
        else ...[
          const SizedBox(height: AppTheme.spacing16),
          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _otpController,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '6자리 인증 코드',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: !_isVerifyingOtp &&
                                _otpRemaining != null &&
                                _otpRemaining != Duration.zero
                            ? _verifyOtp
                            : null,
                        child: _isVerifyingOtp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('확인'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otpController,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '6자리 인증 코드',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        maxWidth: 100,
                      ),
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: !_isVerifyingOtp &&
                                  _otpRemaining != null &&
                                  _otpRemaining != Duration.zero
                              ? _verifyOtp
                              : null,
                          child: _isVerifyingOtp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('확인'),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: AppTheme.spacing8),
          if (_otpRemaining != null && _otpRemaining != Duration.zero)
            Text(
              '남은 시간 ${_formatDuration(_otpRemaining!)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray600),
            )
          else
            Text(
              '인증 코드가 도착하지 않았다면 재전송을 눌러주세요.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray600),
            ),
        ],
      ],
    );
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return '학교 이메일을 입력해주세요.';
    }
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.ac\.kr$');
    if (!regex.hasMatch(value)) {
      return '.ac.kr 도메인의 이메일만 사용할 수 있어요.';
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _cleanMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}

enum NicknameStatus { initial, checking, available, unavailable, invalid }

class NicknameValidationResult {
  const NicknameValidationResult(this.isValid, this.message);

  final bool isValid;
  final String? message;
}
