import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/app_user.dart';
import '../auth/auth_constants.dart';
import '../auth/auth_session.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final AuthSession session;

  const LoginScreen({super.key, required this.session});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  AppRole _role = AppRole.staff;
  bool _pickedRole = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isAdmin => _role.isAdmin;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.session.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      final user = widget.session.user;
      if (user == null) {
        throw AuthException('Could not sign in. Please try again.');
      }
      if (user.isAdmin != _isAdmin) {
        await widget.session.signOut();
        if (mounted) {
          setState(() {
            _error = user.isAdmin
                ? 'This account is registered as an administrator. '
                    'Choose Admin to sign in.'
                : 'This account is registered as staff. '
                    'Choose Staff to sign in.';
          });
        }
        return;
      }
      if (mounted) context.go('/dashboard');
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = _pickedRole;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            icon: !picked
                ? Icons.lock_outline_rounded
                : _isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.badge_outlined,
            title: !picked ? 'Welcome back' : 'Sign in as ${_role.label}',
            subtitle: !picked
                ? 'First, tell us how you are signing in to the Paradise '
                      'Funeral Home management system.'
                : _isAdmin
                ? 'Sign in with your administrator account.'
                : 'Sign in with your staff account.',
          ),
          const SizedBox(height: 24),
          RoleSelector(
            role: _role,
            onChanged: _busy
                ? null
                : (role) => setState(() {
                    _role = role;
                    _error = null;
                  }),
          ),
          if (!picked) ...[
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _pickedRole = true;
                  _error = null;
                }),
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('New here? Create an account'),
            ),
          ] else ...[
            const SizedBox(height: 22),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Enter your email';
                      if (!text.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.key_rounded, size: 19),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) return 'Enter your password';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(message: _error!),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded, size: 19),
                label: Text(_busy ? 'Signing in...' : 'Sign In'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _pickedRole = false;
                      _error = null;
                    }),
              child: Text(
                'Not signing in as ${_role.label.toLowerCase()}? '
                'Change account type',
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => context.go('/register'),
              child: const Text('New here? Create an account'),
            ),
          ],
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final AuthSession session;

  const RegisterScreen({super.key, required this.session});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _accessCtrl = TextEditingController();
  AppRole _role = AppRole.staff;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  bool get _isAdmin => _role.isAdmin;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _accessCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.session.register(
        name: _isAdmin ? '' : _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        role: _role,
        accessCode: _isAdmin ? _accessCtrl.text : null,
      );
      if (!mounted) return;
      if (_isAdmin) {
        context.go('/dashboard');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded, size: 26),
          title: const Text('Account submitted'),
          content: const Text(
            'Your staff account was created and is awaiting administrator '
            'approval. You will be able to sign in once an administrator '
            'approves it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/login');
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            icon: _isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.person_add_alt_1_rounded,
            title: 'Create your account',
            subtitle: _isAdmin
                ? 'Register an administrator account. An access code is required.'
                : 'Register a staff account. An administrator must approve it before you can sign in.',
          ),
          const SizedBox(height: 20),
          RoleSelector(
            role: _role,
            onChanged: _busy
                ? null
                : (role) => setState(() {
                    _role = role;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isAdmin) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.badge_outlined, size: 19),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter your email';
                    if (!text.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.key_rounded, size: 19),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return 'Use at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  textInputAction: _isAdmin
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.key_rounded, size: 19),
                  ),
                  validator: (value) {
                    if (value != _passwordCtrl.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                if (_isAdmin) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _accessCtrl,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Administrator access code',
                      prefixIcon: Icon(Icons.vpn_key_rounded, size: 19),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter the access code';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_add_alt_1_rounded,
                      size: 19,
                    ),
              label: Text(
                _busy
                    ? 'Creating account...'
                    : _isAdmin
                    ? 'Create admin account'
                    : 'Create staff account',
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => context.go('/login'),
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class RoleSelector extends StatelessWidget {
  final AppRole role;
  final ValueChanged<AppRole>? onChanged;

  const RoleSelector({super.key, required this.role, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    Widget chip(AppRole value, IconData icon, String label) {
      final selected = role == value;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onChanged == null ? null : () => onChanged!(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? scheme.onPrimary : palette.muted,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          chip(AppRole.staff, Icons.badge_outlined, 'Staff'),
          chip(AppRole.admin, Icons.shield_outlined, 'Admin'),
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.heroStart, palette.heroEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.heroStart, palette.heroEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 27),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Bitter',
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: palette.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
