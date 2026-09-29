// @vitest-environment jsdom
import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { SITE_PROFILE } from "@/lib/site";
import { NumazuHero } from "./numazu-hero";

describe("NumazuHero", () => {
  it("自治体の紹介から議案一覧へ案内する", () => {
    render(<NumazuHero />);

    const heroHeading = SITE_PROFILE.branding.heroHeading!;
    expect(
      screen.getByRole("region", {
        name: heroHeading,
      })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("heading", {
        level: 1,
        name: heroHeading,
      })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /議案を見てみる/ })
    ).toHaveAttribute("href", "/bills");
    expect(screen.queryByRole("img")).not.toBeInTheDocument();
  });
});
