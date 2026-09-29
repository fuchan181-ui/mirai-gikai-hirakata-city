import type { Metadata } from "next";
import { OpenDataApiReference } from "@/features/open-data/client/components/open-data-api-reference";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

export const metadata: Metadata = {
  title: `オープンデータAPI | ${SITE_NAME}`,
  description:
    `${SITE_PROFILE.jurisdiction.councilName}の議案データとAIインタビューデータをオープンデータとして取得できるAPIのリファレンスです。`,
};

export default function OpenDataApiPage() {
  return <OpenDataApiReference />;
}
