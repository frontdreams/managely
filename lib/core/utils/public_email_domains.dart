/// Mirrors managely-backend/lib/public-email-domains.js — used here only
/// for instant client-side feedback on the organization sign-up form; the
/// backend re-validates authoritatively in routes/organizations.js, since
/// a client-side check alone is trivially bypassed.
const Set<String> publicEmailDomains = {
  'gmail.com', 'googlemail.com',
  'yahoo.com', 'yahoo.co.uk', 'yahoo.co.in', 'ymail.com', 'rocketmail.com',
  'outlook.com', 'hotmail.com', 'live.com', 'msn.com',
  'icloud.com', 'me.com', 'mac.com',
  'aol.com',
  'protonmail.com', 'proton.me', 'pm.me',
  'mail.com', 'gmx.com', 'gmx.net',
  'zoho.com',
  'yandex.com', 'yandex.ru',
  'qq.com', '163.com', '126.com', 'sina.com',
  'inbox.com', 'fastmail.com', 'tutanota.com', 'hey.com',
};

bool isPublicEmailDomain(String email) {
  final at = email.lastIndexOf('@');
  if (at == -1 || at == email.length - 1) return false;
  return publicEmailDomains.contains(email.substring(at + 1).toLowerCase());
}
