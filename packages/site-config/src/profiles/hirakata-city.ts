import type { RuntimeReadySiteProfile } from "../types";
import { SHARED_EXTERNAL_LINKS } from "./shared-external-links";

export const hirakataCityProfile = {
  id: "hirakata-city",
  runtime: { status: "ready" },
  branding: {
    name: "みらい議会＠枚方市",
    description:
      "枚方市議会でいま何が決まっているかを、わかりやすく伝えるプラットフォーム",
    heroHeading: "大阪と京都の間、枚方。",
    heroSubHeading:
      "このまちのこれからを決める市議会の動きを、身近な言葉でお届けします。",
    heroImageAlt: "枚方の風景イメージ",
  },
  jurisdiction: {
    kind: "city",
    name: "枚方市",
    councilName: "枚方市議会",
  },
  features: {
    showComingSoonBills: false,
  },
  externalLinks: {
    ...SHARED_EXTERNAL_LINKS,
    githubRepository: "https://github.com/fuchan181-ui/mirai-gikai-fukuoka-city",
    report: "https://forms.gle/wJXXMt6cv2ZdiCgg6",
    councilOfficial: "https://www.city.hirakata.osaka.jp/0000011280.html",
    sourceTerms: "https://www.city.hirakata.osaka.jp/0000000269.html",
  },
} as const satisfies RuntimeReadySiteProfile;
