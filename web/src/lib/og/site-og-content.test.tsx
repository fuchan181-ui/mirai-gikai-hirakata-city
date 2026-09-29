// @vitest-environment jsdom

import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";
import { SiteOgContent } from "./site-og-content";

describe("SiteOgContent", () => {
  it("有効な機能と非公式サービスであることを表示する", () => {
    render(
      <SiteOgContent
        logoDataUrl="data:image/png;base64,logo"
        screenshotDataUrl="data:image/png;base64,screenshot"
      />
    );

    expect(screen.getByText(/議案を知る.*探す.*審議を追う/)).toBeTruthy();
    expect(
      screen.getByText(
        `${SITE_PROFILE.jurisdiction.name}・${SITE_PROFILE.jurisdiction.councilName}の公式サービスではありません`
      )
    ).toBeTruthy();
    expect(screen.queryByText(/意見を届ける/)).toBeNull();
  });

  it("サイト画面の上へスマートフォンフレームを重ねる", () => {
    render(
      <SiteOgContent
        logoDataUrl="data:image/png;base64,logo"
        screenshotDataUrl="data:image/png;base64,screenshot"
      />
    );

    const preview = screen.getByAltText(`${SITE_NAME}のモバイル表示`);
    const frame = screen.getByRole("img", { name: "スマートフォンフレーム" });
    expect(preview.compareDocumentPosition(frame)).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING
    );
  });
});
