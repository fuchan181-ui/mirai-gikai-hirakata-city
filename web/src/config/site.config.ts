import { SITE_PROFILE } from "@/lib/site";

const DEFAULT_SITE_URL =
  "https://mirai-gikai-hirakata-city-web-three.vercel.app";
const siteUrl = process.env.NEXT_PUBLIC_WEB_URL || DEFAULT_SITE_URL;

/**
 * 枚方市版サイト基本設定
 */
export const siteConfig = {
  name: SITE_PROFILE.branding.name,
  description: SITE_PROFILE.branding.description,
  url: siteUrl,
  ogImage: `${siteUrl.replace(/\/$/, "")}/ogp.png`,
  favicon: "/favicon.png",
  councilName: SITE_PROFILE.jurisdiction.councilName,
  cityName: SITE_PROFILE.jurisdiction.name,
  officialUrl: SITE_PROFILE.externalLinks.councilOfficial,
  billsUrl: SITE_PROFILE.externalLinks.sourceTerms,
  operatorName: "さち",
  jurisdictionCourt: "大阪地方裁判所",
  twitterHashtag: "みらい議会枚方市版",
} as const;
