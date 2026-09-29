import { ArrowRight } from "lucide-react";
import Link from "next/link";
import { routes } from "@/lib/routes";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";
import { Container } from "../layouts/container";
import { Button } from "../ui/button";

export function NumazuHero() {
  const heroHeading =
    SITE_PROFILE.branding.heroHeading ?? "大阪と京都の間、枚方。";
  const heroSubHeading =
    SITE_PROFILE.branding.heroSubHeading ??
    `このまちのこれからを決める${SITE_PROFILE.jurisdiction.councilName}の動きを、身近な言葉でお届けします。`;

  return (
    <Container className="pt-24 md:pt-6">
      <section
        aria-labelledby="hero-heading"
        className="overflow-hidden rounded-3xl border border-[#f5e3e7] bg-[#fff5f7] px-6 py-8 sm:px-10 sm:py-10"
      >
        <div className="flex flex-col items-start justify-center max-w-2xl">
          <p className="mb-2 text-xs font-bold tracking-widest text-primary-accent">
            {SITE_NAME}
          </p>
          <h1
            id="hero-heading"
            className="text-2xl leading-snug font-bold tracking-tight text-mirai-text sm:text-3xl"
          >
            {heroHeading}
          </h1>
          <p className="mt-3 text-sm leading-7 text-mirai-text-secondary sm:text-base">
            {heroSubHeading}
          </p>
          <Button asChild variant="outline" size="sm" className="mt-5">
            <Link href={routes.billsList()}>
              議案を見てみる
              <ArrowRight aria-hidden="true" />
            </Link>
          </Button>
        </div>
      </section>
    </Container>
  );
}
