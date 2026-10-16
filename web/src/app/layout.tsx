import "./globals.css";
import type { Metadata, Viewport } from "next";
import { Noto_Sans_JP, Noto_Serif_JP } from "next/font/google";
import NextTopLoader from "nextjs-toploader";
import type { ReactNode } from "react";
import { ThemeProvider } from "@/components/theme/theme-provider";
import { siteConfig } from "@/config/site.config";
import { env } from "@/lib/env";
import { ogImageUrls } from "@/lib/og/og-image-urls";
import { SITE_DESCRIPTION, SITE_NAME, SITE_PROFILE } from "@/lib/site";

const notoSansJP = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "700"],
  display: "swap",
  preload: false,
});

// Lexend Giga はビルド時の Google Fonts 解決エラー（module-not-found）を防ぐため、
// 安全なシステムフォント fallback を備えたローカル定義とし、head の link で補完します。
const lexendGiga = {
  variable: "font-lexend",
};

// トピックの代表意見など、引用文を明朝体で表示するために使用
const notoSerifJP = Noto_Serif_JP({
  variable: "--font-noto-serif-jp",
  subsets: ["latin"],
  weight: ["500", "600"],
  display: "swap",
  preload: false,
});

const siteTitle = SITE_NAME;
const siteDescription = SITE_DESCRIPTION;
const siteName = SITE_NAME;

// OGP画像およびmetadataBaseの基準URL（本番環境URLをフォールバックとして確実に保証）
const baseSiteUrl =
  env.webUrl && !env.webUrl.includes("localhost")
    ? env.webUrl
    : siteConfig.url;

// サイト全体のOGP画像（静的アイキャッチ画像 /ogp.png）
const ogImage = {
  url: ogImageUrls.site(baseSiteUrl),
  width: 1200,
  height: 630,
  alt: `${SITE_NAME}のOGPイメージ`,
};

export const metadata: Metadata = {
  metadataBase: new URL(baseSiteUrl),
  title: siteTitle,
  description: siteDescription,
  keywords: [
    siteName,
    SITE_PROFILE.jurisdiction.name,
    SITE_PROFILE.jurisdiction.councilName,
    "議案",
    "市政",
    "条例",
    "予算",
    "解説",
  ],
  icons: {
    icon: [{ url: "/favicon.png", type: "image/png" }],
    apple: "/favicon.png",
  },
  manifest: "/manifest.json",
  openGraph: {
    title: siteTitle,
    description: siteDescription,
    images: [ogImage],
    siteName,
  },
  twitter: {
    card: "summary_large_image",
    title: siteTitle,
    description: siteDescription,
    images: [ogImage.url],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#fa9db0" },
    { media: "(prefers-color-scheme: dark)", color: "#181214" },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="ja" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin="anonymous"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Lexend+Giga:wght@400;700;800;900&display=swap"
          rel="stylesheet"
        />
      </head>
      <body
        className={`${notoSansJP.variable} ${lexendGiga.variable} ${notoSerifJP.variable} font-sans antialiased bg-mirai-surface-light`}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <NextTopLoader showSpinner={false} color="#f4a8b9" />
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
