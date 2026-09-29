/**
 * OGP 画像で使う色。globals.css のトークンと同じ値。
 *
 * Satori は CSS 変数を読めないので実値を持つしかない。散らばると globals.css を
 * 変えたときに追従できないので、対応をここ1箇所に置く。
 */
export const OG_COLORS = {
  /** --color-mirai-text */
  text: "#1f2937",
  /** --color-mirai-text-secondary */
  textSecondary: "#404040",
  /** --color-mirai-text-muted */
  textMuted: "#6f6f74",
  /** --color-mirai-border */
  border: "#d2d2d2",
  /** --primary */
  primary: "#be3b63",
  /** --primary-accent */
  primaryAccent: "#a83e5c",
  /** --color-mirai-light-gradient-start */
  surfaceAccent: "#fae1e6",
  /** カードの地 */
  card: "white",
  /** --color-mirai-gradient-end → --color-mirai-gradient-start の順に流す */
  gradient:
    "linear-gradient(-30deg, rgb(252, 236, 238) 1%, rgb(244, 168, 185) 99%)",
  /** 画像全体の地。淡いピンクから --background（#fbf8f7）へ */
  pageBackground:
    "linear-gradient(177deg, rgb(253, 242, 244) 0%, rgb(251, 248, 247) 100%)",
  /** サイト OGP: やさしい薄いピンクグラデーション */
  siteBackgroundSea:
    "linear-gradient(135deg, rgb(250, 225, 230) 0%, rgb(253, 242, 244) 48%, rgb(253, 248, 245) 100%)",
  /** MITライセンスの liquidframe を参考にした端末フレーム */
  phoneFrame: "rgb(25, 28, 33)",
  phoneFrameHighlight: "rgb(88, 96, 108)",
  phoneFrameShadow: "rgba(31, 41, 55, 0.22)",
} as const;
