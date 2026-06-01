---
target: dashboard layout
total_score: 23
p0_count: 0
p1_count: 3
timestamp: 2026-05-27T05-32-03Z
slug: dashboard-layout
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Sync dot, loading indicator, timestamp — solid; notification badge always active regardless of real state |
| 2 | Match System / Real World | 3 | Indonesian copy is warm and correct; income icon (arrow_downward) is counter-intuitive; emergency ring ratio is non-obvious |
| 3 | User Control and Freedom | 2 | No undo after adding a transaction; "Kelola →" unresponsive; no dashboard customization |
| 4 | Consistency and Standards | 3 | Token usage excellent; GestureDetector without InkWell on all bento tiles breaks Android ripple convention |
| 5 | Error Prevention | 2 | 4 dead bento tiles are false affordances; "Kelola →" silently does nothing |
| 6 | Recognition Rather Than Recall | 3 | Bento labels present; ring labels at 9px nearly invisible; income icon ambiguous |
| 7 | Flexibility and Efficiency | 2 | Pull-to-refresh and FAB are good; no further efficiency mechanisms |
| 8 | Aesthetic and Minimalist Design | 2 | Five distinct card surfaces on one screen; 4 dead bento tiles; density high for anxiety-reducing app |
| 9 | Error Recovery | 2 | Retry button present; raw bloc message may be technical |
| 10 | Help and Documentation | 1 | No contextual help; "Days to Live" unexplained; coming-soon gives no timeline |
| **Total** | | **23/40** | **Acceptable — significant improvements needed** |

## Anti-Patterns Verdict

LLM assessment: Dashboard reads as a competent implementation of the finance-app template. Token discipline is genuine. The bento grid with 6 tiles (4 dead) is the AI slop tell — pure fintech SaaS reflex.

Deterministic scan: CLI detector unavailable for Dart. Manual findings: fontSize: 9 below minimum in _RingWidget; silent false affordance on "Kelola →"; GestureDetector without InkWell on 6 interactive surfaces.

## Priority Issues

**[P1] Balance card buried behind bento grid** — reorder: DTL → Saldo → Rings → Bento → Tip → Transactions
**[P1] 4 of 6 bento tiles dead** — remove Bills, Scan, Split, Challenge or collapse into one stub
**[P1] "Kelola →" Quick Access header is silent** — don't pass action text when onActionTap is null
**[P2] Ring widget labels at fontSize 9** — remove override, use AppTextStyles.caption (12px)
**[P2] "Transaksi Terkini" shows today-only** — rename to "Hari Ini" or fall back to recent N when today is empty

## Persona Red Flags

Casey: saldo buried 280dp down; detail link ~80×20dp tap zone (below 44dp minimum)
Jordan: 4 dead tiles, silent "Kelola →", unexplained Days-to-Live concept
Reza (kost student): always-on notification dot adds ambient anxiety; bento grid mismatches "bertahan" brand positioning

## Minor Observations

- GestureDetector without InkWell ripple on 6 interactive bento surfaces
- income category icon (arrow_downward) counter-intuitive
- TipCard is 5th distinct surface pattern — reads as disabled/decorative
- Notification dot hardcoded regardless of real notification state
- Ring delta text also at fontSize 10 — should be caption unmodified
