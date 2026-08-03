#!/usr/bin/env python3
"""Restore the published blog.shawjj Medium archive as static HTML.

The allowlist below is intentionally limited to stories that are currently
published in the blog.shawjj publication. Drafts and other account exports are
never considered, even when they are present in Medium's archive.
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import mimetypes
import re
import urllib.parse
import urllib.request
from pathlib import Path


PUBLISHED = [
    {
        "id": "47e8ec43631",
        "slug": "making-useful-gestures-and-swipes-on-macos-with-bettertouchtool-47e8ec43631",
    },
    {
        "id": "22f8b22a5f58",
        "slug": "unsubscribe-from-venmo-payment-emails-22f8b22a5f58",
    },
    {
        "id": "7e3bef27c0e3",
        "slug": "how-to-force-aptx-on-sony-wh-1000xm2-7e3bef27c0e3",
    },
    {
        "id": "58ff562ab69",
        "slug": "where-are-my-organic-views-on-medium-coming-from-58ff562ab69",
    },
    {
        "id": "23ea17a2363a",
        "slug": "block-ads-everywhere-with-adguard-for-ios-23ea17a2363a",
    },
    {
        "id": "f6274330dc6f",
        "slug": "speed-up-time-machine-backups-by-10x-f6274330dc6f",
    },
    {
        "id": "b63708e93cfb",
        "slug": "adding-a-medium-publication-sitemap-to-search-console-b63708e93cfb",
    },
    {
        "id": "e57acacb37",
        "slug": "mac-randomly-shuts-down-finding-the-cause-e57acacb37",
    },
]

SITE_URL = "https://shawjj.com"


def text_content(value: str) -> str:
    value = re.sub(r"<[^>]+>", "", value)
    value = html.unescape(value)
    value = value.replace("\xa0", " ").replace("\u200a", " ")
    return re.sub(r"\s+", " ", value).strip()


def match_one(pattern: str, source: str, label: str) -> str:
    match = re.search(pattern, source, re.DOTALL | re.IGNORECASE)
    if not match:
        raise ValueError(f"Could not find {label}")
    return match.group(1).strip()


def image_extension(url: str, content_type: str | None) -> str:
    path_suffix = Path(urllib.parse.urlparse(url).path).suffix.lower()
    if path_suffix in {".jpg", ".jpeg", ".png", ".gif", ".webp"}:
        return ".jpg" if path_suffix == ".jpeg" else path_suffix
    guessed = mimetypes.guess_extension((content_type or "").split(";", 1)[0].strip())
    return ".jpg" if guessed in {".jpe", ".jpeg"} else (guessed or ".jpg")


def localize_images(body: str, post_id: str, output_root: Path) -> str:
    image_dir = output_root / "writing" / "assets"
    image_dir.mkdir(parents=True, exist_ok=True)
    image_urls = re.findall(r'<img\b[^>]*\bsrc="([^"]+)"', body)
    background_urls = re.findall(
        r"background-image:\s*url\((https://cdn-images[^)]+)\)", body
    )
    urls = list(dict.fromkeys([*image_urls, *background_urls]))

    for index, url in enumerate(urls, start=1):
        request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = response.read()
            extension = image_extension(url, response.headers.get("Content-Type"))
        filename = f"{post_id}-{index:02d}{extension}"
        (image_dir / filename).write_bytes(payload)
        local_url = f"/writing/assets/{filename}"
        body = body.replace(url, local_url)

    def add_image_attributes(match: re.Match[str]) -> str:
        tag = match.group(0)
        if " loading=" not in tag:
            tag = tag[:-1] + ' loading="lazy" decoding="async">'
        if " alt=" not in tag:
            tag = tag[:-1] + ' alt="">'
        return tag

    return re.sub(r"<img\b[^>]*>", add_image_attributes, body)


def clean_body(body: str) -> str:
    body = re.sub(
        r'<iframe\b[^>]*src="https://upscri\.be/[^"]+"[^>]*>\s*</iframe>',
        "",
        body,
        flags=re.IGNORECASE,
    )
    body = re.sub(
        r'<h3\b[^>]*graf--title[^>]*>.*?</h3>', "", body, count=1, flags=re.DOTALL
    )
    body = re.sub(
        r'<h4\b[^>]*graf--subtitle[^>]*>.*?</h4>', "", body, count=1, flags=re.DOTALL
    )
    body = re.sub(r"<h4\b", "<h2", body)
    body = body.replace("</h4>", "</h2>")
    body = re.sub(r'<hr\b[^>]*class="section-divider"[^>]*>', "", body)
    body = body.replace(
        "https://blog.shawjj.com/sitemap/sitemap.xml", f"{SITE_URL}/sitemap.xml"
    )
    for item in PUBLISHED:
        body = body.replace(
            f"https://blog.shawjj.com/{item['slug']}",
            f"{SITE_URL}/writing/{item['slug']}/",
        )
    body = body.replace("https://blog.shawjj.com/", f"{SITE_URL}/writing/")
    body = body.replace("https://blog.shawjj.com", f"{SITE_URL}/writing/")
    return body.strip()


def parse_post(source_file: Path, item: dict[str, str], output_root: Path) -> dict[str, str]:
    source = source_file.read_text(encoding="utf-8")
    export_title = text_content(match_one(r"<title>(.*?)</title>", source, "title"))
    body = match_one(
        r'<section\s+data-field="body"[^>]*>(.*)</section>\s*<footer>',
        source,
        "article body",
    )
    live_title_match = re.search(
        r'<h3\b[^>]*graf--title[^>]*>(.*?)</h3>', body, re.DOTALL | re.IGNORECASE
    )
    title = text_content(live_title_match.group(1)) if live_title_match else export_title
    subtitle_match = re.search(
        r'<section\s+data-field="subtitle"[^>]*>(.*?)</section>',
        source,
        re.DOTALL | re.IGNORECASE,
    )
    subtitle = text_content(subtitle_match.group(1)) if subtitle_match else ""
    published = match_one(
        r'<time\s+class="dt-published"\s+datetime="([^"]+)"',
        source,
        "publication date",
    )
    body = clean_body(body)
    body = localize_images(body, item["id"], output_root)
    return {
        **item,
        "title": title,
        "subtitle": subtitle,
        "published": published,
        "body": body,
        "old_url": f"https://blog.shawjj.com/{item['slug']}",
        "new_url": f"{SITE_URL}/writing/{item['slug']}/",
    }


def page_shell(*, title: str, description: str, canonical: str, main: str, extra_head: str = "") -> str:
    title_html = html.escape(title)
    description_html = html.escape(description, quote=True)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#ffffff">
  <title>{title_html}</title>
  <meta name="description" content="{description_html}">
  <link rel="canonical" href="{html.escape(canonical, quote=True)}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="{title_html}">
  <meta property="og:description" content="{description_html}">
  <meta property="og:url" content="{html.escape(canonical, quote=True)}">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="alternate" type="application/atom+xml" title="JJ Shaw — Writing" href="{SITE_URL}/feed.xml">
  <link rel="stylesheet" href="/writing.css">
{extra_head}
</head>
<body>
  <header class="writing-header">
    <a class="writing-wordmark" href="/">JJ Shaw</a>
    <nav aria-label="Primary navigation">
      <a href="/writing/">Writing</a>
      <a href="mailto:hello@shawjj.com">Email</a>
      <a href="https://www.linkedin.com/in/shawjj" rel="noopener noreferrer">LinkedIn</a>
    </nav>
  </header>
  {main}
</body>
</html>
"""


def render_post(post: dict[str, str]) -> str:
    published_date = dt.datetime.fromisoformat(post["published"].replace("Z", "+00:00"))
    date_label = published_date.strftime("%B %-d, %Y")
    description = post["subtitle"] or post["title"]
    schema = {
        "@context": "https://schema.org",
        "@type": "Article",
        "headline": post["title"],
        "description": description,
        "datePublished": post["published"],
        "dateModified": post["published"],
        "author": {"@type": "Person", "name": "JJ Shaw", "url": SITE_URL},
        "mainEntityOfPage": post["new_url"],
    }
    extra_head = (
        f'<meta property="article:published_time" content="{post["published"]}">\n'
        f'  <script type="application/ld+json">{json.dumps(schema, ensure_ascii=False)}</script>'
    )
    subtitle = (
        f'<p class="article-subtitle">{html.escape(post["subtitle"])}</p>'
        if post["subtitle"]
        else ""
    )
    main = f"""<main class="article-shell">
    <article>
      <header class="article-header">
        <p class="eyebrow"><a href="/writing/">Writing</a></p>
        <h1>{html.escape(post["title"])}</h1>
        {subtitle}
        <p class="article-meta">JJ Shaw · <time datetime="{post['published']}">{date_label}</time></p>
      </header>
      <div class="article-body e-content">
        {post['body']}
      </div>
      <footer class="article-footer">
        <a href="/writing/">← All writing</a>
      </footer>
    </article>
  </main>"""
    return page_shell(
        title=f"{post['title']} — JJ Shaw",
        description=description,
        canonical=post["new_url"],
        main=main,
        extra_head=extra_head,
    )


def render_index(posts: list[dict[str, str]]) -> str:
    rows = []
    for post in posts:
        published_date = dt.datetime.fromisoformat(post["published"].replace("Z", "+00:00"))
        subtitle = (
            f'<p>{html.escape(post["subtitle"])}</p>' if post["subtitle"] else ""
        )
        rows.append(
            f"""<li>
          <a href="/writing/{post['slug']}/">
            <div><h2>{html.escape(post['title'])}</h2>{subtitle}</div>
            <time datetime="{post['published']}">{published_date.strftime('%Y')}</time>
          </a>
        </li>"""
        )
    main = f"""<main class="writing-index">
    <ol class="writing-list">
      {''.join(rows)}
    </ol>
  </main>"""
    return page_shell(
        title="Writing — JJ Shaw",
        description="Writing by JJ Shaw on technology, productivity, and making computers work better.",
        canonical=f"{SITE_URL}/writing/",
        main=main,
    )


def render_feed(posts: list[dict[str, str]]) -> str:
    updated = max(post["published"] for post in posts)
    entries = []
    for post in posts:
        summary = post["subtitle"] or post["title"]
        entries.append(
            f"""  <entry>
    <title>{html.escape(post['title'])}</title>
    <link href="{post['new_url']}"/>
    <id>{post['new_url']}</id>
    <updated>{post['published']}</updated>
    <summary>{html.escape(summary)}</summary>
    <author><name>JJ Shaw</name></author>
  </entry>"""
        )
    return f"""<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>JJ Shaw — Writing</title>
  <link href="{SITE_URL}/feed.xml" rel="self"/>
  <link href="{SITE_URL}/writing/"/>
  <id>{SITE_URL}/writing/</id>
  <updated>{updated}</updated>
{chr(10).join(entries)}
</feed>
"""


def render_sitemap(posts: list[dict[str, str]]) -> str:
    urls = [
        (f"{SITE_URL}/", None),
        (f"{SITE_URL}/writing/", max(post["published"][:10] for post in posts)),
        *[(post["new_url"], post["published"][:10]) for post in posts],
    ]
    nodes = []
    for url, lastmod in urls:
        lastmod_node = f"<lastmod>{lastmod}</lastmod>" if lastmod else ""
        nodes.append(f"  <url><loc>{url}</loc>{lastmod_node}</url>")
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{chr(10).join(nodes)}
</urlset>
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("export_dir", type=Path)
    parser.add_argument("output_root", type=Path, nargs="?", default=Path.cwd())
    args = parser.parse_args()

    posts_dir = args.export_dir / "posts"
    output_root = args.output_root.resolve()
    posts = []
    for item in PUBLISHED:
        matches = list(posts_dir.glob(f"*{item['id']}.html"))
        if len(matches) != 1:
            raise ValueError(f"Expected one exported post for {item['id']}, found {len(matches)}")
        post = parse_post(matches[0], item, output_root)
        destination = output_root / "writing" / item["slug"] / "index.html"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(render_post(post), encoding="utf-8")
        posts.append(post)

    posts.sort(key=lambda post: post["published"], reverse=True)
    (output_root / "writing").mkdir(parents=True, exist_ok=True)
    (output_root / "writing" / "index.html").write_text(
        render_index(posts), encoding="utf-8"
    )
    (output_root / "feed.xml").write_text(render_feed(posts), encoding="utf-8")
    (output_root / "sitemap.xml").write_text(render_sitemap(posts), encoding="utf-8")
    (output_root / "robots.txt").write_text(
        f"User-agent: *\nAllow: /\n\nSitemap: {SITE_URL}/sitemap.xml\n", encoding="utf-8"
    )
    manifest = [
        {
            key: post[key]
            for key in ("id", "title", "published", "old_url", "new_url")
        }
        for post in posts
    ]
    (output_root / "writing" / "migration-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Restored {len(posts)} published articles")


if __name__ == "__main__":
    main()
