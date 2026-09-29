"use client";

import Image from "next/image";
import type { ChangeEvent, RefObject } from "react";
import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useStickToBottomContext } from "use-stick-to-bottom";
import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from "@/components/ai-elements/conversation";
import {
  PromptInput,
  PromptInputBody,
  PromptInputError,
  PromptInputHint,
  type PromptInputMessage,
  PromptInputTextarea,
} from "@/components/ai-elements/prompt-input";
import { Button } from "@/components/ui/button";
import type { BillWithContent } from "@/features/bills/shared/types";
import type { ChatPageContext } from "@/features/chat/shared/types/chat-page-context";
import { useIsDesktop } from "@/hooks/use-is-desktop";
import { useMediaQuery } from "@/hooks/use-media-query";
import { useViewportHeight } from "@/hooks/use-viewport-height";
import { SITE_NAME, SITE_PROFILE } from "@/lib/site";
import {
  CHAT_PANEL_RESPONSIVE_CLASSES,
  MobileChatDialog,
} from "./mobile-chat-dialog";
import { SystemMessage } from "./system-message";
import { UserMessage } from "./user-message";

interface ChatWindowProps {
  billContext?: BillWithContent;
  hasInterviewConfig?: boolean;
  difficultyLevel: string;
  chatState: ReturnType<typeof import("@ai-sdk/react").useChat>;
  isOpen: boolean;
  onClose: () => void;
  pageContext?: ChatPageContext;
  disableAutoFocus?: boolean;
  returnFocusRef: RefObject<HTMLElement | null>;
  sessionId: string;
}

/**
 * Conversation内部で使用するコンポーネント
 * useStickToBottomContextを使用するために分離
 */
function ChatMessages({
  billContext,
  hasInterviewConfig,
  difficultyLevel,
  messages,
  sendMessage,
  status,
  pageContext,
  sessionId,
}: {
  billContext?: BillWithContent;
  hasInterviewConfig?: boolean;
  difficultyLevel: string;
  messages: ChatWindowProps["chatState"]["messages"];
  sendMessage: ChatWindowProps["chatState"]["sendMessage"];
  status: ChatWindowProps["chatState"]["status"];
  pageContext?: ChatWindowProps["pageContext"];
  sessionId: string;
}) {
  const { scrollToBottom } = useStickToBottomContext();
  const userMessageLength = messages.filter((x) => x.role === "user").length;
  const isResponding = status === "streaming" || status === "submitted";

  // メッセージが追加されたら自動的にスクロール
  useEffect(() => {
    if (userMessageLength > 0) {
      scrollToBottom();
    }
  }, [userMessageLength, scrollToBottom]);

  return (
    <>
      <div className="flex flex-col gap-4">
        {/* 初期メッセージ */}
        <div className="flex flex-col gap-1">
          <p className="text-sm font-bold leading-[1.8] text-mirai-text">
            {SITE_PROFILE.jurisdiction.councilName}
            や議案について、気になることをAIに質問してください。
          </p>
          {billContext && (
            <p className="text-sm font-bold leading-[1.8] text-mirai-text">
              本文中のテキストを選択すると簡単にAIに質問できます
            </p>
          )}
        </div>

        {/* サンプル質問チップ */}
        <div className="flex flex-wrap gap-3">
          {(billContext
            ? [`この議案のポイントは？`, "この議案は私の暮らしにどう関わる？"]
            : [
                `${SITE_NAME}って何？`,
                "市議会って何をするところ？",
                "注目の議案について教えて",
              ]
          ).map((question) => {
            return (
              <button
                key={question}
                type="button"
                disabled={isResponding}
                className="px-3 py-1 text-xs leading-[2] text-primary-accent border border-primary rounded-2xl hover:bg-mirai-surface-gray disabled:opacity-50 disabled:cursor-not-allowed"
                onClick={() => {
                  sendMessage({
                    text: question,
                    metadata: {
                      billContext,
                      hasInterviewConfig,
                      difficultyLevel,
                      pageContext,
                      sessionId,
                    },
                  });
                }}
              >
                {question}
              </button>
            );
          })}
        </div>
      </div>
      {messages.map((message) => {
        const isStreaming =
          status === "streaming" && message.id === messages.at(-1)?.id;

        return message.role === "user" ? (
          <UserMessage key={message.id} message={message} />
        ) : (
          <SystemMessage
            key={message.id}
            message={message}
            isStreaming={isStreaming}
            billId={billContext?.id}
            billName={billContext?.bill_content?.title ?? billContext?.name}
          />
        );
      })}
      {status === "submitted" && (
        <span className="text-sm text-mirai-text-muted">考え中...</span>
      )}
    </>
  );
}

export function ChatWindow({
  billContext,
  hasInterviewConfig,
  difficultyLevel,
  chatState,
  isOpen,
  onClose,
  pageContext,
  disableAutoFocus = false,
  returnFocusRef,
  sessionId,
}: ChatWindowProps) {
  const [input, setInput] = useState("");
  const [isMounted, setIsMounted] = useState(false);
  const { messages, sendMessage, status, error } = chatState;
  const isDesktop = useIsDesktop();
  const isPc = useMediaQuery("(min-width: 1000px)");
  const viewportHeight = useViewportHeight();
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const isResponding = status === "streaming" || status === "submitted";

  useEffect(() => {
    setIsMounted(true);
  }, []);

  // Auto-resize textarea based on content
  const handleInputChange = (e: ChangeEvent<HTMLTextAreaElement>) => {
    setInput(e.target.value);

    // Auto-resize
    const textarea = e.target;
    textarea.style.height = "auto";
    textarea.style.height = `${textarea.scrollHeight}px`;
  };

  const handleSubmit = async (message: PromptInputMessage) => {
    const hasText = Boolean(message.text);

    if (!hasText || isResponding) {
      return;
    }

    // Send message with context and difficulty level in metadata
    // By default, this sends a HTTP POST request to the /api/chat endpoint.
    sendMessage({
      text: message.text ?? "",
      metadata: {
        billContext,
        hasInterviewConfig,
        difficultyLevel,
        pageContext,
        sessionId,
      },
    });

    // Reset form
    setInput("");
  };

  const chatPanelContent = (
    <>
      {/* メッセージエリア（スクロール可能） */}
      <Conversation className="flex-1 min-h-0">
        <ConversationContent className="p-0 flex flex-col gap-3 pc:pt-6 pb-2 px-6">
          <ChatMessages
            billContext={billContext}
            hasInterviewConfig={hasInterviewConfig}
            difficultyLevel={difficultyLevel}
            messages={messages}
            sendMessage={sendMessage}
            status={status}
            pageContext={pageContext}
            sessionId={sessionId}
          />
        </ConversationContent>
        <ConversationScrollButton />
      </Conversation>

      {/* 入力エリア（固定下部） */}
      <div className="px-6 pb-4 pt-2">
        <PromptInput
          onSubmit={handleSubmit}
          className="flex items-end gap-2.5 py-2 pl-6 pr-4 bg-[#fff0f5] rounded-[50px] border-mirai-gradient divide-y-0"
        >
          <PromptInputBody className="flex-1">
            <PromptInputTextarea
              ref={textareaRef}
              onChange={handleInputChange}
              value={input}
              placeholder="わからないことをAIに質問する"
              rows={1}
              submitOnEnter={isDesktop}
              // min-w-0, wrap-anywhere が無いと長文で親幅を押し広げてしまう
              className={`!min-h-0 min-w-0 wrap-anywhere text-sm font-medium leading-[1.5em] tracking-[0.01em] placeholder:text-mirai-text-placeholder placeholder:font-medium placeholder:leading-[1.5em] placeholder:tracking-[0.01em] placeholder:no-underline border-none focus:ring-0 bg-transparent shadow-none !py-2 !px-0`}
            />
          </PromptInputBody>
          <Button
            type="submit"
            variant="ghost"
            size="icon"
            disabled={!input || isResponding}
            className="flex-shrink-0 w-10 h-10 p-0 rounded-full transition-all hover:brightness-90 active:scale-95 disabled:opacity-50 flex items-center justify-center overflow-hidden border border-[#f5d0da]"
            style={{
              background: "linear-gradient(135deg, #ffd1dc 0%, #fdf0f3 100%)",
            }}
          >
            <SendPlaneIcon />
          </Button>
        </PromptInput>
        <PromptInputError status={status} error={error} />
        {messages.length > 0 && <PromptInputHint />}
      </div>
    </>
  );

  // body直下にPortalでマウント（クライアントサイドのみ）
  if (!isMounted) {
    return null;
  }

  // PCでは常設の補助領域、モバイルでは背景を操作不能にするモーダルとして扱う
  if (isPc) {
    return createPortal(
      <section
        aria-label={`${SITE_PROFILE.jurisdiction.councilName}や議案についてAIに質問する`}
        className={`fixed inset-x-0 bottom-0 z-50 bg-[#fff5f7] border border-[#f5e3e7] shadow-md rounded-t-2xl flex flex-col pc:h-[70vh] xl:right-[calc(calc(100%-1180px)/2)] ${CHAT_PANEL_RESPONSIVE_CLASSES}`}
      >
        {chatPanelContent}
      </section>,
      document.body
    );
  }

  return (
    <MobileChatDialog
      disableAutoFocus={disableAutoFocus}
      initialFocusRef={textareaRef}
      isOpen={isOpen}
      onClose={onClose}
      returnFocusRef={returnFocusRef}
      style={
        viewportHeight && !isDesktop
          ? { maxHeight: `${viewportHeight}px` }
          : undefined
      }
    >
      {chatPanelContent}
    </MobileChatDialog>
  );
}

function SendPlaneIcon() {
  return (
    <svg
      width="23"
      height="23"
      viewBox="10 11.8 18 18"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className="pointer-events-none"
    >
      <path
        d="M20.8104 29.5653C20.4161 29.5653 20.1258 29.4256 19.9396 29.1463C19.7534 28.8724 19.5973 28.5274 19.4714 28.1112L17.7544 22.2456L11.8231 20.5122C11.4233 20.3918 11.092 20.2411 10.8291 20.0604C10.5662 19.8742 10.4348 19.5839 10.4348 19.1896C10.4348 18.872 10.5525 18.6009 10.788 18.3763C11.029 18.1518 11.3275 17.9738 11.6835 17.8423L25.9038 12.3958C26.09 12.3246 26.2652 12.2698 26.4295 12.2315C26.5938 12.1931 26.7444 12.174 26.8814 12.174C27.1716 12.174 27.4016 12.2588 27.5714 12.4286C27.7412 12.5984 27.8261 12.8284 27.8261 13.1187C27.8261 13.2611 27.8069 13.4144 27.7686 13.5787C27.7302 13.7376 27.6755 13.9101 27.6043 14.0963L22.1905 28.2591C22.0372 28.6534 21.8483 28.9683 21.6237 29.2038C21.3992 29.4448 21.1281 29.5653 20.8104 29.5653ZM18.2227 20.7587L23.2174 15.7639C23.4639 15.5175 23.7514 15.2573 24.08 14.9835C24.4141 14.7097 24.729 14.4523 25.0247 14.2113C24.6578 14.3811 24.3018 14.5481 23.9568 14.7124C23.6118 14.8712 23.2612 15.0191 22.9053 15.156L13.0554 18.9185C13.0006 18.935 12.9623 18.9569 12.9404 18.9842C12.924 19.0062 12.9157 19.0308 12.9157 19.0582C12.9157 19.0801 12.9267 19.102 12.9486 19.1239C12.9705 19.1458 13.0116 19.165 13.0718 19.1814L18.2227 20.7587ZM20.9501 27.1007C20.9775 27.1007 21.0021 27.087 21.024 27.0597C21.0459 27.0378 21.0651 26.9994 21.0815 26.9446L24.844 17.0948C24.9809 16.7388 25.1288 16.3855 25.2876 16.035C25.4519 15.6845 25.6217 15.3231 25.797 14.9506C25.5615 15.2519 25.3013 15.5723 25.0165 15.9118C24.7372 16.2459 24.4771 16.5362 24.2361 16.7826L19.2413 21.7774L20.8186 26.9282C20.8405 26.9885 20.8597 27.0323 20.8761 27.0597C20.898 27.087 20.9227 27.1007 20.9501 27.1007Z"
        fill="#be3b63"
      />
    </svg>
  );
}
