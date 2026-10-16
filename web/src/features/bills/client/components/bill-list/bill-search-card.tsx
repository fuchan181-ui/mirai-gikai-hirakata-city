import { MessageSquareText } from "lucide-react";
import Link from "next/link";
import { RubySafeLineClamp } from "@/components/ruby-safe-line-clamp";
import { Card } from "@/components/ui/card";
import { routes } from "@/lib/routes";
import { formatDateWithDots } from "@/lib/utils/date";
import type { BillListItem } from "../../../shared/types";
import { ReviewCompleteBadge } from "../bill-detail/review-status-banner";
import { BillNumberLabel } from "./bill-number-label";
import { BillPill } from "./bill-pill";
import { BillStatusBadge } from "./bill-status-badge";
import { BillTag } from "./bill-tag";

/**
 * 議案一覧（/bills）のカード。
 *
 * サムネイル画像は非表示とし、タイトル・ステータス・要約・タグ等をシンプルにレイアウトする。
 */
export function BillSearchCard({ bill }: { bill: BillListItem }) {
  const title = bill.bill_content?.title || bill.name;
  const summary = bill.bill_content?.summary;
  const reportCount = bill.publicReportCount ?? 0;
  const hasBadges =
    bill.tags.length > 0 ||
    bill.hasPublicInterview ||
    reportCount > 0 ||
    bill.hasDebate;

  return (
    <Card className="overflow-hidden border border-foreground shadow-none transition-colors hover:bg-muted/50">
      <Link
        href={routes.billDetail(bill.id)}
        className="flex flex-col gap-2 p-4"
      >
        <div className="flex min-w-0 flex-1 flex-col gap-1.5">
          {/* タイトルは省略しない。何の議案かが読めないと選べない。 */}
          <h3 className="text-base font-bold leading-relaxed">
            {title}
            {bill.is_review_completed && (
              <>
                {" "}
                <ReviewCompleteBadge size={14} top="1px" />
              </>
            )}
          </h3>

          <div className="flex flex-wrap items-center gap-3">
            <BillStatusBadge status={bill.status} className="w-fit" />
            <BillNumberLabel billNumber={bill.bill_number} />
            {bill.submitted_date && (
              <span className="text-xs font-medium text-mirai-text-muted">
                {formatDateWithDots(bill.submitted_date)} 提出
              </span>
            )}
          </div>

          {summary && (
            <RubySafeLineClamp
              text={summary}
              lineClamp={2}
              className="text-xs leading-relaxed text-mirai-text-secondary"
            />
          )}
        </div>

        {hasBadges && (
          <div className="flex flex-wrap items-center gap-2">
            {bill.tags.map((tag) => (
              <BillTag key={tag.id} tag={tag} />
            ))}
            {bill.hasPublicInterview && (
              <BillPill>AIインタビュー受付中</BillPill>
            )}
            {bill.hasDebate && (
              <BillPill>
                <span className="inline-flex items-center gap-1">
                  <MessageSquareText className="size-3.5" aria-hidden="true" />
                  本会議討論あり
                </span>
              </BillPill>
            )}
            {/* 回答が集まっている議案だけ数字を出す。0人と書くと参加をためらわせる。 */}
            {reportCount > 0 && (
              <BillPill>💬 {reportCount}人がAIインタビューに回答</BillPill>
            )}
          </div>
        )}
      </Link>
    </Card>
  );
}
