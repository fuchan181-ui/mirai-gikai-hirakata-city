import { LinkButton } from "@/components/top/link-button";
import { EXTERNAL_LINKS } from "@/config/external-links";
import { SITE_PROFILE } from "@/lib/site";

/**
 * デスクトップメニュー: アクションボタン（サイドバー内）
 */
export function DesktopMenuActionButtons() {
  return (
    <div className="flex flex-col gap-3">
      <LinkButton
        href={EXTERNAL_LINKS.COUNCIL_OFFICIAL}
        icon={{
          src: "/icons/info-icon.svg",
          alt: "",
          width: 20,
          height: 20,
        }}
      >
        {SITE_PROFILE.jurisdiction.councilName}の公式ページ
      </LinkButton>
    </div>
  );
}
