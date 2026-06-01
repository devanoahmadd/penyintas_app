---
target: dashboard layout spacing
total_score: 22
p0_count: 0
p1_count: 2
timestamp: 2026-05-27T07-29-21Z
slug: dashboard-layout-spacing
---
## Skor Kesehatan Desain

| # | Heuristik | Skor | Isu Utama |
|---|-----------|-------|-----------|
| 1 | Visibilitas Status Sistem | 3 | Tidak berubah dari critique sebelumnya |
| 2 | Kesesuaian dengan Dunia Nyata | 3 | Tidak berubah |
| 3 | Kontrol & Kebebasan Pengguna | 2 | Tidak berubah |
| 4 | Konsistensi & Standar | 2 | Gap 8dp dipakai untuk dua konteks berbeda; lima nilai padding di level kartu setara |
| 5 | Pencegahan Kesalahan | 2 | SizedBox(height: 2) hardcoded |
| 6 | Pengenalan daripada Ingatan | 3 | Section header membantu orientasi |
| 7 | Fleksibilitas & Efisiensi | 2 | Tidak berubah |
| 8 | Desain Estetis & Minimalis | 2 | Ritme spacing flat (14-8-8-14-14-8) tanpa variasi semantik |
| 9 | Pemulihan dari Kesalahan | 2 | Tidak berubah |
| 10 | Bantuan & Dokumentasi | 1 | Tidak berubah |
| **Total** | | **22/40** | |

## Isu Prioritas

[P1] Gap Rings→Bento 8dp identik dengan Saldo→Ring — tidak ada section break visual antar kelompok berbeda
[P1] Ritme spacing 14-8-8-14-14-8 tidak mencerminkan grouping semantik; 8dp dipakai untuk dua konteks
[P2] SizedBox(height: 2) hardcoded di DaysToLiveCard L99 — satu-satunya nilai spacing di luar token
[P2] fontSize: 9 eyebrow TipCard — terlewat dari fix sebelumnya di ring widget
[P3] Bell container 40dp vs avatar 44dp dalam satu header row
[P3] Visibility icon 16dp dalam 44x44 tap zone — terlalu kecil secara visual

## Catatan Minor

- RingWidget sub text masih fontSize: 10 (label+delta sudah 12, tapi sub belum)
- TipCard lightbulb icon rasio 50% (13/26) vs ring widget 45% (20/44)
