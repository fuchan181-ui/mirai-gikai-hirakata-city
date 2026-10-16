// @vitest-environment jsdom
import { render, waitFor } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ThemeProvider } from "./theme-provider";

const useThemeMock = vi.hoisted(() => vi.fn());

vi.mock("next-themes", () => ({
  ThemeProvider: ({ children }: { children: ReactNode }) => children,
  useTheme: useThemeMock,
}));

beforeEach(() => {
  document.head.innerHTML = '<meta name="theme-color" content="#fa9db0">';
});

describe("ThemeProvider", () => {
  it("選択中のダークテーマをブラウザUIの色にも反映する", async () => {
    useThemeMock.mockReturnValue({ resolvedTheme: "dark" });

    render(<ThemeProvider>content</ThemeProvider>);

    await waitFor(() => {
      expect(
        document.querySelector<HTMLMetaElement>('meta[name="theme-color"]')
          ?.content
      ).toBe("#181214");
    });
  });

  it("選択中のライトテーマをブラウザUIの色にも反映する", async () => {
    document.head.innerHTML = '<meta name="theme-color" content="#181214">';
    useThemeMock.mockReturnValue({ resolvedTheme: "light" });

    render(<ThemeProvider>content</ThemeProvider>);

    await waitFor(() => {
      expect(
        document.querySelector<HTMLMetaElement>('meta[name="theme-color"]')
          ?.content
      ).toBe("#fa9db0");
    });
  });
});
