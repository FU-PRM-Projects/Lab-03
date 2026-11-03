"""Xuất các góp ý của CodeRabbit trên mọi PR ra docs/code-review.md.

Chạy từ gốc repo:

    python tools/export_coderabbit.py

Chỉ dùng thư viện chuẩn. Không cần token với repo public; nếu bị giới hạn 60 lượt/giờ
của GitHub thì đặt biến môi trường GITHUB_TOKEN.

Script chỉ ghi đè phần nằm giữa hai dấu `<!-- coderabbit:start -->` và
`<!-- coderabbit:end -->`. Cột "Kết luận" và "Ghi chú" nhóm đã điền được giữ lại theo ID,
nên chạy lại bao nhiêu lần cũng không mất phần đánh giá.
"""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.request
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

REPO = "FU-PRM-Projects/Lab-03"
BOT = "coderabbitai[bot]"
OUT = Path(__file__).resolve().parent.parent / "docs" / "code-review.md"
START = "<!-- coderabbit:start -->"
END = "<!-- coderabbit:end -->"
PENDING = "Chưa xét"
SEVERITIES = ["Critical", "Major", "Minor", "Trivial"]

TEMPLATE = f"""# AI code review

Mỗi PR vào `main` đều được CodeRabbit review tự động. File này gom mọi góp ý của nó và
ghi lại nhóm đánh giá từng góp ý đúng hay sai.

Phần bảng sinh bằng `python tools/export_coderabbit.py`. Chạy lại khi có PR mới; cột
**Kết luận** và **Ghi chú** đã điền được giữ nguyên.

Giá trị cho cột Kết luận:

- `Đúng, đã sửa`: lỗi thật, ghi commit sửa ở cột Ghi chú.
- `Đúng, chưa sửa`: lỗi thật nhưng để lại, ghi lý do.
- `Sai`: AI hiểu nhầm code hoặc yêu cầu, ghi vì sao.
- `Không cần`: đúng về kỹ thuật nhưng không đáng sửa trong phạm vi Lab.

{START}
{END}

## Nhận xét về CodeRabbit

_Nhóm tự viết sau khi điền xong cột Kết luận: AI tìm ra bao nhiêu lỗi thật, bao nhiêu góp ý
sai, loại lỗi nào nó bắt tốt, loại nào bỏ sót, và có nên tin kết quả review của nó không._
"""


@dataclass
class Finding:
    id: str
    pr: int
    location: str
    severity: str
    category: str
    effort: str
    title: str
    url: str


def get(path: str) -> list[dict]:
    """GET có phân trang, trả về toàn bộ phần tử."""
    items: list[dict] = []
    url = f"https://api.github.com/repos/{REPO}/{path}"
    url += ("&" if "?" in url else "?") + "per_page=100"
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "export-coderabbit"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    while url:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as res:
            items += json.load(res)
            links = res.headers.get("Link", "")
        match = re.search(r'<([^>]+)>; rel="next"', links)
        url = match.group(1) if match else ""
    return items


def clean(body: str) -> str:
    """Bỏ icon HTML để dễ bắt mẫu."""
    return re.sub(r"<(?:img|picture|source)[^>]*>|</picture>", "", body)


def short_id(pr: int, body: str, fallback: int) -> str:
    match = re.search(r"cr-comment:v1:([0-9a-f]{8})", body)
    return f"{pr}-{match.group(1) if match else fallback}"


def cell(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ").strip()


def from_inline(c: dict) -> Finding | None:
    """Góp ý gắn vào dòng code. Đầu comment: **Major** · **Loại** · **Công sức**."""
    body = clean(c["body"])
    head = re.search(r"\*\*\s*(\w+)\*\* · \*\*(.+?)\*\* · \*\*(.+?)\*\*", body)
    # Tiêu đề là dòng in đậm đầu tiên nằm ngoài các khối <details>.
    outside = re.sub(r"<details>.*?</details>", "", body, flags=re.S)
    title = re.search(r"^\*\*(?!\s*\w+\*\* ·)(.+?)\*\*\s*$", outside, re.M)
    if not head or not title:
        return None
    pr = int(c["pull_request_url"].rsplit("/", 1)[1])
    end = c.get("line") or c.get("original_line")
    start = c.get("start_line") or c.get("original_start_line")
    lines = f"{start}-{end}" if start and start != end else f"{end}"
    return Finding(
        id=short_id(pr, body, c["id"]),
        pr=pr,
        location=f"`{c['path']}:{lines}`",
        severity=head.group(1),
        category=head.group(2),
        effort=head.group(3),
        title=title.group(1),
        url=c["html_url"],
    )


def from_review(pr: int, review: dict) -> list[Finding]:
    """Góp ý nằm trong thân review (Follow-up, Nitpick, Outside diff...)."""
    found = []
    body = clean(review["body"])
    for block, block_id in re.findall(
        r"<blockquote>(.*?)<!-- cr-comment:v1:([0-9a-f]+) -->", body, re.S
    ):
        head = re.search(
            r"`([\d-]+)`: \*\*[^*]*?([A-Z][\w &]+?)\*\* \| \*\*[^*]*?(\w+)\*\* \| \*\*[^*]*?([A-Z][\w ]+?)\*\*",
            block,
        )
        title = re.search(r"^\*\*(.+?)\*\*\s*$", block, re.M)
        source = re.search(r"\[Open the source location\]\([^)]*/blob/[0-9a-f]+/([^)#]+)", block)
        if not head or not title:
            continue
        lines, category, severity, effort = head.groups()
        path = source.group(1) if source else "?"
        found.append(
            Finding(
                id=f"{pr}-{block_id[:8]}",
                pr=pr,
                location=f"`{path}:{lines}`",
                severity=severity,
                category=category,
                effort=effort,
                title=title.group(1),
                url=review["html_url"],
            )
        )
    return found


def collect() -> list[Finding]:
    inline = [
        c
        for c in get("pulls/comments")
        if c["user"]["login"] == BOT and not c.get("in_reply_to_id")
    ]
    findings = [f for c in inline if (f := from_inline(c))]
    prs = [p for p in get("pulls?state=all") if not p["user"]["login"].endswith("[bot]")]
    for p in prs:
        for review in get(f"pulls/{p['number']}/reviews"):
            if review["user"]["login"] == BOT:
                findings += from_review(p["number"], review)
    unique = {f.id: f for f in findings}
    return sorted(unique.values(), key=lambda f: (-f.pr, SEVERITIES.index(f.severity) if f.severity in SEVERITIES else 9, f.location))


def old_verdicts(text: str) -> dict[str, tuple[str, str]]:
    """Đọc lại Kết luận và Ghi chú đã điền, theo ID ở cột đầu."""
    verdicts = {}
    for row in re.findall(r"^\| (\d+-[0-9a-z]+) \|(.*)\|\s*$", text, re.M):
        cols = [c.strip() for c in re.split(r"(?<!\\)\|", row[1])]
        if len(cols) >= 2:
            verdicts[row[0]] = (cols[-2], cols[-1])
    return verdicts


def render(findings: list[Finding], verdicts: dict[str, tuple[str, str]]) -> str:
    by_sev = Counter(f.severity for f in findings)
    by_cat = Counter(f.category for f in findings)
    by_pr = Counter(f.pr for f in findings)
    judged = Counter(verdicts.get(f.id, (PENDING, ""))[0] for f in findings)
    out = [
        START,
        "",
        "## Tổng hợp",
        "",
        f"{len(findings)} góp ý trên {len(by_pr)} PR "
        f"({', '.join(f'#{n}: {k}' for n, k in sorted(by_pr.items(), reverse=True))}).",
        "",
        "| Mức độ | Số góp ý |",
        "|---|---|",
        *(f"| {s} | {by_sev[s]} |" for s in SEVERITIES if by_sev[s]),
        "",
        "| Loại | Số góp ý |",
        "|---|---|",
        *(f"| {c} | {k} |" for c, k in by_cat.most_common()),
        "",
        "| Kết luận | Số góp ý |",
        "|---|---|",
        *(f"| {v} | {k} |" for v, k in judged.most_common()),
        "",
        "## Từng góp ý",
        "",
        "| ID | PR | Vị trí | Mức độ | Loại | Công sức | Góp ý của AI | Kết luận | Ghi chú |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for f in findings:
        verdict, note = verdicts.get(f.id, (PENDING, ""))
        out.append(
            f"| {f.id} | #{f.pr} | {f.location} | {f.severity} | {f.category} | {f.effort} "
            f"| [{cell(f.title)}]({f.url}) | {verdict} | {note} |"
        )
    out += ["", END]
    return "\n".join(out)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    text = OUT.read_text(encoding="utf-8") if OUT.exists() else TEMPLATE
    if START not in text or END not in text:
        sys.exit(f"{OUT} thiếu dấu {START} / {END}")
    try:
        findings = collect()
    except urllib.error.HTTPError as e:
        if e.code in (403, 429):
            sys.exit("GitHub chặn vì quá 60 lượt/giờ. Đặt GITHUB_TOKEN rồi chạy lại.")
        raise
    before, rest = text.split(START, 1)
    _, after = rest.split(END, 1)
    OUT.write_text(
        before + render(findings, old_verdicts(text)) + after,
        encoding="utf-8",
        newline="\n",
    )
    print(f"Đã ghi {len(findings)} góp ý vào {OUT}")


if __name__ == "__main__":
    main()
