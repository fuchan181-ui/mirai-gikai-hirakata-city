import type { Metadata } from "next";
import { GeneralQuestionsPage } from "@/features/general-questions/server/components/general-questions-page";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

export const metadata: Metadata = {
  title: `一般質問 | ${SITE_NAME}`,
  description: `${SITE_PROFILE.jurisdiction.councilName}の一般質問を会期・開催日・質問項目から確認できます。`,
};

export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{
    session?: string;
    year?: string;
    questionKind?: string;
    topic?: string;
    role?: string;
  }>;
}) {
  return <GeneralQuestionsPage filters={await searchParams} />;
}
