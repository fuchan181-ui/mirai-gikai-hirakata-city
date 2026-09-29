import { describe, expect, it } from "vitest";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";
import { buildBillChatSystemNormalPrompt } from "./bill-chat-system-normal";

describe("buildBillChatSystemNormalPrompt", () => {
  it("4つのパラメータがプロンプトに埋め込まれる", () => {
    const result = buildBillChatSystemNormalPrompt(
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

  it("難易度「ふつう」セクションが含まれる", () => {
    const result = buildBillChatSystemNormalPrompt("a", "b", "c", "d");

    expect(result).toContain("回答の難易度：ふつう");
  });

  it("市議会とサービスの説明が含まれる", () => {
    const result = buildBillChatSystemNormalPrompt("a", "b", "c", "d");

    expect(result).toContain(SITE_NAME);
    expect(result).toContain(SITE_PROFILE.jurisdiction.councilName);
    expect(result).toContain("外部サイトのURLやリンク");
    expect(result).toContain("一切回答に含めないでください");
  });

  it("knowledgeSource を渡すと <knowledge_source> セクションが含まれる", () => {
    const result = buildBillChatSystemNormalPrompt(
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
    const result = buildBillChatSystemNormalPrompt("a", "b", "c", "d");

    expect(result).not.toContain("<knowledge_source>");
  });
});
