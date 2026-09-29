import Image from "next/image";
import Link from "next/link";
import { routes } from "@/lib/routes";
import { SITE_NAME } from "@/lib/site";
import { SiteTitle } from "./site-title";

/**
 * ヘッダーのロゴおよびサイトタイトル
 */
export function HeaderLogo() {
  return (
    <Link
      href={routes.home()}
      className="flex items-center space-x-2"
      aria-label="ホーム"
    >
      <Image
        src="/img/logo.png"
        alt={SITE_NAME}
        width={38}
        height={38}
        className="h-9 w-9 object-contain"
        priority
      />
      <SiteTitle />
    </Link>
  );
}

