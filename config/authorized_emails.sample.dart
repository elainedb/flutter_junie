// Sample config for authorized emails for CI or external pipelines.
//
// Some CI setups expect this file at `config/authorized_emails.sample.dart`.
// The GitHub Actions workflow in this repo will copy this file (if present)
// to `lib/config/authorized_emails.dart`. If not present, it falls back to
// `lib/config/authorized_emails.sample.dart`.
//
// Do NOT commit `lib/config/authorized_emails.dart` (it's ignored by .gitignore).

const List<String> authorizedEmails = <String>[
  'lala@gmail.com',
  'lele@gmail.com',
  'lili@gmail.com',
];
