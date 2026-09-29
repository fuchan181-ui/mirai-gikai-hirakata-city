import { SITE_PROFILE } from "@/lib/site";

/**
 * 枚方市版管理サイト基本設定
 */
export const siteConfig = {
  name: `${SITE_PROFILE.branding.name} 管理画面`,
  description: `${SITE_PROFILE.branding.name}の管理・運営ダッシュボード`,
  url: process.env.ADMIN_URL || "http://localhost:3001",
  councilName: SITE_PROFILE.jurisdiction.councilName,
  cityName: SITE_PROFILE.jurisdiction.name,
  officialUrl: SITE_PROFILE.externalLinks.councilOfficial,
  operatorName: "さち",
  jurisdictionCourt: "大阪地方裁判所",
} as const;

