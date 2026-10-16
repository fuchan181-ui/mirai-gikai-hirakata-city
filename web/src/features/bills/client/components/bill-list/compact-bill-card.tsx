import { Card } from "@/components/ui/card";
import { formatDateWithDots } from "@/lib/utils/date";
import type { BillWithContent } from "../../../shared/types";
import { ReviewCompleteBadge } from "../bill-detail/review-status-banner";
import { BillNumberLabel } from "./bill-number-label";
import { BillStatusBadge } from "./bill-status-badge";

interface CompactBillCardProps {
  bill: BillWithContent;
  className?: string;
}

/**
 * コンパクトな水平レイアウトの議案カード
 * 過去の定例会セクションや過去の定例会の議案一覧ページで使用
 */
export function CompactBillCard({ bill, className }: CompactBillCardProps) {
  const displayTitle = bill.bill_content?.title || bill.name;

  return (
    <Card
      className={`border border-[#f5e3e7] dark:border-[#38252b] bg-[#fff5f7] dark:bg-[#251b1f] shadow-none hover:bg-[#ffeef2] dark:hover:bg-[#2d2025] transition-colors overflow-hidden ${className ?? ""}`}
    >
      <div className="p-4 flex flex-col gap-2">
        <h3 className="font-bold text-[15px] leading-[1.6] line-clamp-2">
          {displayTitle}
          {bill.is_review_completed && (
            <>
              {" "}
              <ReviewCompleteBadge size={14} top="1px" />
            </>
          )}
        </h3>
        <div className="flex items-center gap-3">
          <BillStatusBadge status={bill.status} className="w-fit" />
          <BillNumberLabel billNumber={bill.bill_number} />
          {bill.submitted_date && (
            <span className="text-xs text-muted-foreground">
              {formatDateWithDots(bill.submitted_date)} 提出
            </span>
          )}
        </div>
      </div>
    </Card>
  );
}
