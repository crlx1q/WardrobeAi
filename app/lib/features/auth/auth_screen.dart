import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      showSnack(context, 'Введите email и пароль', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (_isLogin) {
        await auth.login(email, password);
      } else {
        await auth.register(email, password, _name.text.trim());
      }
    } catch (e) {
      if (mounted) showSnack(context, ApiClient.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.tt;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset('assets/logo.png', width: 48, height: 48, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Text('Capsule', style: text.displayMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ваш AI-гардероб. Каталогизируйте вещи и получайте идеальные образы каждый день.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 36),
                  FloatingCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(_isLogin ? 'Вход' : 'Регистрация', style: text.headlineSmall),
                        const SizedBox(height: 24),
                        if (!_isLogin) ...[
                          _label(context, 'Имя'),
                          TextField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(hintText: 'Как вас зовут?'),
                          ),
                          const SizedBox(height: 18),
                        ],
                        _label(context, 'Email'),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'you@example.com'),
                        ),
                        const SizedBox(height: 18),
                        _label(context, 'Пароль'),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(hintText: '••••••••'),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: context.cs.onPrimary),
                                )
                              : Text(_isLogin ? 'Войти' : 'Создать аккаунт'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : () => setState(() => _isLogin = !_isLogin),
                      child: Text.rich(
                        TextSpan(
                          text: _isLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
                          style: text.bodyMedium,
                          children: [
                            TextSpan(
                              text: _isLogin ? 'Зарегистрироваться' : 'Войти',
                              style: text.bodyMedium?.copyWith(
                                color: context.cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: context.cs.onSurfaceVariant,
          ),
        ),
      );
}
