import { describe, expect, it } from "vitest";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";
import { buildBillChatSystemHardPrompt } from "./bill-chat-system-hard";

describe("buildBillChatSystemHardPrompt", () => {
  it("4つのパラメータがプロンプトに埋め込まれる", () => {
    const result = buildBillChatSystemHardPrompt(
      "テスト議案名",
      "テスト議案タイトル",
      "テスト議案要約",
      "テスト議案詳細"
    );

    expect(result).toContain("テスト議案名");
    expect(result).toContain("テスト議案タイトル");
    expect(result).toContain("テスト議案要約");
    expect(result).toContain("テスト議案詳細");
  });

  it("難易度「難しい」セクションが含まれる", () => {
    const result = buildBillChatSystemHardPrompt("a", "b", "c", "d");

    expect(result).toContain("回答の難易度：難しい");
    expect(result).toContain("専門用語を正確に使用");
  });

  it("市議会とサービスの説明が含まれる", () => {
    const result = buildBillChatSystemHardPrompt("a", "b", "c", "d");

    expect(result).toContain(SITE_NAME);
    expect(result).toContain(SITE_PROFILE.jurisdiction.councilName);
    expect(result).toContain("外部サイトのURLやリンク");
    expect(result).toContain("一切回答に含めないでください");
  });

  it("knowledgeSource を渡すと <knowledge_source> セクションが含まれる", () => {
    const result = buildBillChatSystemHardPrompt(
      "a",
      "b",
      "c",
      "d",
      "補足知識"
    );

    expect(result).toContain("補足ナレッジ");
    expect(result).toContain("補足知識");
  });

  it("knowledgeSource を省略するとセクションごと出ない", () => {
    const result = buildBillChatSystemHardPrompt("a", "b", "c", "d");

    expect(result).not.toContain("<knowledge_source>");
  });
});
