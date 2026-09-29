import { EXTERNAL_LINKS } from "@/config/external-links";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";
import { LinkButton } from "./link-button";

export function About() {
  return (
    <div className="py-10">
      <div className="flex flex-col gap-4 rounded-3xl border border-[#f5e3e7] bg-[#fff5f7] p-6 sm:p-8">
        {/* ヘッダー */}
        <div className="flex flex-col gap-4">
          <h2>
            <span className="font-lexend text-[32px] leading-none font-bold tracking-tight text-mirai-text">
              About
            </span>
          </h2>
          <p className="text-sm font-bold text-primary-accent">
            {SITE_NAME}とは
          </p>
        </div>

        {/* コンテンツ */}
        <div className="flex flex-col gap-6">
          <div className="flex flex-col gap-3">
            <h3 className="text-2xl font-bold leading-[43.2px]">
              {SITE_PROFILE.jurisdiction.councilName}の議論を
              <br />
              できる限りわかりやすく
            </h3>
            <p className="text-[15px] leading-[28px] text-foreground">
              {SITE_NAME}は、{SITE_PROFILE.jurisdiction.councilName}
              でいまどんな議案が審議されているかを、わかりやすく伝えるサービスです。市民の声が市政に届くことを目指して、継続的にアップデートしていきます。
            </p>
            <p className="text-[15px] leading-[28px] text-mirai-text-subtle">
              本サービスは有志が運営する非公式のサービスであり、
              {SITE_PROFILE.jurisdiction.name}および
              {SITE_PROFILE.jurisdiction.councilName}
              が運営するものではありません。議案の正式な内容や議会の日程は、
              {SITE_PROFILE.jurisdiction.councilName}
              の公式ページをご確認ください。
            </p>
          </div>

          {/* 議会の公式ページへ */}
          <LinkButton
            href={EXTERNAL_LINKS.COUNCIL_OFFICIAL}
            icon={{
              src: "/icons/info-icon.svg",
              alt: "",
              width: 23,
              height: 22,
            }}
          >
            {SITE_PROFILE.jurisdiction.councilName}の公式ページ
          </LinkButton>
        </div>
      </div>
    </div>
  );
}
