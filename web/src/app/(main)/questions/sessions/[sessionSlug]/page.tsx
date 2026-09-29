import type { Metadata } from "next";
import { GeneralQuestionSessionPage } from "@/features/general-questions/server/components/general-question-session-page";
import { SITE_NAME } from "@/lib/site";

type Props = { params: Promise<{ sessionSlug: string }> };
export const metadata: Metadata = {
  title: `会期別の一般質問 | ${SITE_NAME}`,
};
export default async function Page({ params }: Props) {
  const { sessionSlug } = await params;
  return <GeneralQuestionSessionPage slug={sessionSlug} />;
}
