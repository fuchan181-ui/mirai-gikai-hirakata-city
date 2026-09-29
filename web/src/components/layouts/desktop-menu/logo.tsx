import Image from "next/image";
import Link from "next/link";
import { routes } from "@/lib/routes";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";

/**
 * デスクトップメニュー: ロゴ (画面左上)
 */
export function DesktopMenuLogo() {
  return (
    <Link
      href={routes.home()}
      className="fixed top-6 left-6 z-50 flex items-center gap-6 hover:opacity-90 transition-opacity"
    >
      {/* ロゴ */}
      <div className="relative w-[100px] h-[100px]">
        <Image
          src="/img/logo.png"
          alt={`${SITE_NAME}ロゴ`}
          fill
          className="object-contain"
          priority
        />
      </div>

      {/* テキスト */}
      <div className="flex flex-col gap-1.5">
        <h1
          className="font-extrabold text-foreground"
          style={{
            fontSize: "30px",
            lineHeight: "1em",
            letterSpacing: "0.1em",
          }}
        >
          {SITE_NAME}
        </h1>
        <p
          className="font-bold text-foreground"
          style={{
            fontSize: "16px",
            lineHeight: "2em",
          }}
        >
          {SITE_PROFILE.jurisdiction.councilName}の議論をわかりやすく
        </p>
      </div>
    </Link>
  );
}
