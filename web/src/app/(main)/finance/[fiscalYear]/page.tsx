import type { Metadata } from "next";
import { FiscalYearPage } from "@/features/finance/server/components/fiscal-year-page";
import { formatFiscalYear } from "@/features/finance/shared/utils/format-fiscal-year";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ fiscalYear: string }>;
}): Promise<Metadata> {
  const { fiscalYear } = await params;
  const year = Number(fiscalYear);
  if (!Number.isInteger(year)) {
    return { title: `財政 | ${SITE_NAME}` };
  }
  const label = formatFiscalYear(year);
  return {
    title: `${label}の予算と決算 | ${SITE_NAME}`,
    description: `${SITE_PROFILE.jurisdiction.name}の一般会計の${label}予算の内訳と、その予算がどう使われたかを公式資料からまとめて表示します。`,
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ fiscalYear: string }>;
}) {
  const { fiscalYear } = await params;
  return <FiscalYearPage fiscalYear={Number(fiscalYear)} />;
}
