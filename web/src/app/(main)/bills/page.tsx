import type { Metadata } from "next";
import { BillsListPage } from "@/features/bills/server/components/bills-list-page";
import type { BillsListSearchParams } from "@/features/bills/shared/utils/parse-bills-list-params";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

export const metadata: Metadata = {
  title: `議案を検索する | ${SITE_NAME}`,
  description: `${SITE_PROFILE.jurisdiction.councilName}に提出された議案を、審議状況や分野から探せます。`,
};

type Props = {
  searchParams: Promise<BillsListSearchParams>;
};

export default async function BillsPage({ searchParams }: Props) {
  return <BillsListPage searchParams={await searchParams} />;
}
