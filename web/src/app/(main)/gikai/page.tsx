import type { Metadata } from "next";
import { CouncilSessionsPage } from "@/features/council-sessions/server/components/council-sessions-page";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

export const metadata: Metadata = {
  title: `定例会・臨時会の一覧 | ${SITE_NAME}`,
  description: `${SITE_PROFILE.jurisdiction.councilName}の定例会・臨時会の一覧です。会期ごとに提出された議案を辿れます。`,
};

export default function GikaiSessionsPage() {
  return <CouncilSessionsPage />;
}
