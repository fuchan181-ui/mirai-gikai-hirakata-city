import type { Metadata } from "next";
import { FinancePage } from "@/features/finance/server/components/finance-page";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

export const metadata: Metadata = {
  title: `予算とその使われ方 | ${SITE_NAME}`,
  description: `${SITE_PROFILE.jurisdiction.name}の一般会計の予算内訳と、その予算がどう使われたかを公式資料からまとめて表示します。`,
};

export default function Page() {
  return <FinancePage />;
}
