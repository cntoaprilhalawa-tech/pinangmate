import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_view_model.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _validateEmail(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Email wajib diisi';
  if (!_emailRe.hasMatch(s)) return 'Format email tidak valid';
  return null;
}

String? _validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
  if (v.length < 6) return 'Minimal 6 karakter';
  return null;
}
void _afterAuth(BuildContext context) {
  if (context.canPop()) {
    context.pop(); // kembali ke halaman asal (mis. tab Rencana)
  } else {
    context.go('/');
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'PinangMate',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    onTap: (_) => context.read<AuthViewModel>().clearError(),
                    tabs: const [Tab(text: 'Masuk'), Tab(text: 'Daftar')],
                  ),
                  const Expanded(
                    child: TabBarView(children: [_LoginForm(), _RegisterForm()]),
                  ),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Jelajahi dulu tanpa akun'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

   Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    final ok = await context
        .read<AuthViewModel>()
        .login(_email.text.trim(), _password.text);
    if (ok && mounted) _afterAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: _hide,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _hide
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    icon: Icon(_hide
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: _validatePassword,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showResetDialog(context, _email.text),
            child: const Text('Lupa kata sandi?'),
          ),
        ),
        if (vm.error != null) _ErrorBanner(vm.error!),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: vm.loading ? null : _submit,
          child: vm.loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Masuk'),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _key = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

    Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    final ok = await context.read<AuthViewModel>().register(
          _nama.text.trim(),
          _email.text.trim(),
          _password.text,
        );
    if (ok && mounted) _afterAuth(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Nama minimal 2 huruf'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: _hide,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Kata sandi',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _hide
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    icon: Icon(_hide
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                obscureText: _hide,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Ulangi kata sandi',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != _password.text ? 'Kata sandi tidak sama' : null,
              ),
            ],
          ),
        ),
        if (vm.error != null) _ErrorBanner(vm.error!),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: vm.loading ? null : _submit,
          child: vm.loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Daftar'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: cs.error))),
        ],
      ),
    );
  }
}

Future<void> _showResetDialog(BuildContext context, String initialEmail) async {
  final controller = TextEditingController(text: initialEmail.trim());
  final formKey = GlobalKey<FormState>();
  final vm = context.read<AuthViewModel>();
  final messenger = ScaffoldMessenger.of(context);

  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reset kata sandi'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: _validateEmail,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
          },
          child: const Text('Kirim'),
        ),
      ],
    ),
  );

  if (send != true) return;
  final ok = await vm.resetPassword(controller.text.trim());
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? 'Jika email terdaftar, tautan reset sudah dikirim.'
            : (vm.error ?? 'Gagal mengirim tautan reset.'),
      ),
    ),
  );
}