/// Who this account is, in terms of app permissions — separate from
/// [ManagerLevel] (which is the user's self-described experience as a
/// manager) and [SubscriptionTier] (which is what they're paying for).
///
/// SECURITY NOTE: the `role` field mirrored on the Firestore user document
/// is for UI/display convenience only — e.g. showing "Admin" somewhere,
/// or letting the client decide whether to even render an admin nav item.
/// It must NEVER be trusted for anything that actually protects data or
/// unlocks a privileged backend action. The real, unforgeable source of
/// truth is a Firebase Auth CUSTOM CLAIM (`admin: true`), set only via the
/// Firebase Admin SDK (see managely-backend/scripts/set-admin.js) — never
/// settable by the client itself. Firestore security rules and the
/// backend's `requireAdmin` middleware both check the custom claim, not
/// this field. A user editing their own Firestore doc to say
/// `role: admin` should do nothing, because nothing privileged ever reads
/// that field to decide what's allowed.
enum UserRole { user, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
    }
  }
}