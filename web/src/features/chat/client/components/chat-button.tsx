"use client";

import { useChat } from "@ai-sdk/react";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from "react";
import { Button } from "@/components/ui/button";
import type { BillWithContent } from "@/features/bills/shared/types";
import type { ChatPageContext } from "@/features/chat/shared/types/chat-page-context";
import { ChatWindow } from "./chat-window";

// アニメーション定数
const ANIMATION_DURATION = {
  SIZE_TRANSITION: 300, // ボタンサイズ変更のアニメーション時間（ms）
  TEXT_FADE_IN: 200, // テキストフェードイン時間（ms）
  TEXT_CHANGE_DELAY: 250, // テキスト内容変更までの待機時間（サイズアニメーション終了間際）
} as const;

interface ChatButtonProps {
  billContext?: BillWithContent;
  hasInterviewConfig?: boolean;
  difficultyLevel: string;
  pageContext?: ChatPageContext;
}

export interface ChatButtonRef {
  openWithText: (selectedText: string) => void;
}

import { ENABLE_AI_CHAT } from "@/features/chat/shared/constants";
export { ENABLE_AI_CHAT };

export const ChatButton = forwardRef<ChatButtonRef, ChatButtonProps>(
  (props, ref) => {
    useImperativeHandle(ref, () => ({
      openWithText: () => {},
    }));

    if (!ENABLE_AI_CHAT) {
      return null;
    }

    return <ChatButtonInner {...props} ref={ref} />;
  }
);

ChatButton.displayName = "ChatButton";

const ChatButtonInner = forwardRef<ChatButtonRef, ChatButtonProps>(
  ({ billContext, hasInterviewConfig, difficultyLevel, pageContext }, ref) => {
    const [isOpen, setIsOpen] = useState(false);
    const [isCompact, setIsCompact] = useState(false);
    const [showText, setShowText] = useState(true);
    const [openedWithText, setOpenedWithText] = useState(false);
    const chatTriggerRef = useRef<HTMLButtonElement>(null);
    const pathname = usePathname();

    // Chat state をここで管理することで、モーダルが閉じても状態が保持される
    const chatState = useChat();

    // pathname が変わるたびに新しいセッションIDを発行
    // ページ遷移時にチャットセッションをリセット
    // biome-ignore lint/correctness/useExhaustiveDependencies: pathnameが変わるたびに新しいIDを生成するため意図的に依存配列に含めている
    const sessionId = useMemo(() => crypto.randomUUID(), [pathname]);

    useImperativeHandle(ref, () => ({
      openWithText: (selectedText: string) => {
        // AIからの返答待ち中は新しいメッセージを送信しない
        if (
          chatState.status === "streaming" ||
          chatState.status === "submitted"
        ) {
          return;
        }

        const questionText = `「${selectedText}」について教えてください。`;
        setOpenedWithText(true);
        setIsOpen(true);
        chatState.sendMessage({
          text: questionText,
          metadata: {
            billContext,
            hasInterviewConfig,
            difficultyLevel,
            pageContext,
            sessionId,
          },
        });
      },
    }));

    useEffect(() => {
      let lastScrollY = window.scrollY;

      const handleScroll = () => {
        const currentScrollY = window.scrollY;
        const shouldCompact =
          currentScrollY > lastScrollY && currentScrollY > 0 && !isCompact;
        const shouldExpand = currentScrollY < lastScrollY && isCompact;

        if (shouldCompact || shouldExpand) {
          setIsCompact(shouldCompact);
          setShowText(false);
          setTimeout(() => {
            setShowText(true);
          }, ANIMATION_DURATION.TEXT_CHANGE_DELAY);
        }

        lastScrollY = currentScrollY;
      };

      window.addEventListener("scroll", handleScroll, { passive: true });

      return () => {
        window.removeEventListener("scroll", handleScroll);
      };
    }, [isCompact]);

    return (
      <>
        <div className="fixed max-w-[460px] mx-auto left-6 right-6 bottom-4 z-50 md:bottom-8 flex justify-center pc:hidden">
          <div
            className="relative rounded-[50px] bg-gradient-to-tr from-mirai-gradient-start to-mirai-gradient-end p-[2px] shadow-[2px_2px_2px_0px_rgba(0,0,0,0.25)] origin-center flex transition-[flex-basis] ease-in-out"
            style={{
              flexBasis: isCompact ? "120px" : "100%",
              transitionDuration: `${ANIMATION_DURATION.SIZE_TRANSITION}ms`,
            }}
          >
            <Button
              ref={chatTriggerRef}
              type="button"
              variant="ghost"
              onClick={() => setIsOpen(true)}
              className={`relative bg-[#fff0f5] rounded-[50px] hover:bg-[#ffe6ee] flex items-center w-full py-2 transition-all ease-in-out ${
                isCompact
                  ? "h-[35px] px-4 justify-center gap-2.5"
                  : "h-14 justify-end pr-4 pl-6 gap-2.5"
              }`}
              style={{
                transitionDuration: `${ANIMATION_DURATION.SIZE_TRANSITION}ms`,
              }}
              aria-label="議案について質問する"
              aria-haspopup="dialog"
              aria-expanded={isOpen}
            >
              <span
                className={`text-mirai-text-secondary text-sm font-medium leading-[1.5em] tracking-[0.01em] ${
                  isCompact ? "text-center" : "flex-1 text-left"
                } ${
                  showText
                    ? "opacity-100 transition-opacity ease-in-out"
                    : "opacity-0"
                }`}
                style={
                  showText
                    ? {
                        transitionDuration: `${ANIMATION_DURATION.TEXT_FADE_IN}ms`,
                      }
                    : undefined
                }
              >
                {isCompact ? "AIに質問" : "わからないことをAIに質問する"}
              </span>
              {!isCompact && (
                <div
                  className="relative w-10 h-10 rounded-[20px] flex items-center justify-center flex-shrink-0 overflow-hidden border border-[#f5d0da]"
                  style={{
                    background: "linear-gradient(135deg, #ffd1dc 0%, #fdf0f3 100%)",
                  }}
                >
                  <SendPlaneIcon />
                </div>
              )}
            </Button>
          </div>
        </div>

        <ChatWindow
          billContext={billContext}
          hasInterviewConfig={hasInterviewConfig}
          difficultyLevel={difficultyLevel}
          chatState={chatState}
          isOpen={isOpen}
          onClose={() => {
            setIsOpen(false);
            setOpenedWithText(false);
          }}
          pageContext={pageContext}
          disableAutoFocus={openedWithText}
          returnFocusRef={chatTriggerRef}
          sessionId={sessionId}
        />
      </>
    );
  }
);

ChatButtonInner.displayName = "ChatButtonInner";

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
