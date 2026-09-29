/**
 * suggest_interviewツールの名前（サーバー側ツール定義用）
 */
export const SUGGEST_INTERVIEW_TOOL_NAME = "suggest_interview";

/**
 * suggest_interviewツールのUIメッセージpart type（クライアント側判定用）
 */
export const SUGGEST_INTERVIEW_TOOL_TYPE =
  `tool-${SUGGEST_INTERVIEW_TOOL_NAME}` as const;

/**
 * AIチャットおよびAIアシスト機能の有効化フラグ
 *
 * - false: サイト全体のチャットUI、本文中のAI質問案内ブロック（LongPressSection）、
 *          テキスト選択ツールチップを非表示にし、メインコンテンツを画面中央に配置します。
 * - true:  AIチャットおよび関連案内機能をすべて通常通り有効化します。
 */
export const ENABLE_AI_CHAT = false;
