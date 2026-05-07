import { redirect } from 'next/navigation';

// Per-notification deep-link target.
//
// Universal Links / verified App Links open the installed Tekka app on this
// path (see apps/user/src/app/.well-known/* and the Flutter deep-link
// mapper). On a desktop browser the URL just falls back to the list — the
// recipient can identify and open the broadcast there. We don't render a
// server-side detail view because the notifications list already lives at
// /notifications and avoids a separate auth round-trip here.
export default async function NotificationByIdPage(_props: {
  params: Promise<{ id: string }>;
}) {
  redirect('/notifications');
}
