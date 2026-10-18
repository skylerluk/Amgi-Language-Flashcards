#!/usr/bin/env python3
"""Rebuild the original graded EPUBs and offline translations from graded-stories.json."""
import html
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1] / "AmgiFeatures/Sources/ReaderFeature/Resources"


def write(archive, name, text):
    # Fixed timestamps make an unchanged content rebuild byte-for-byte stable.
    entry = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
    archive.writestr(entry, text.encode("utf-8"))


def main():
    books = json.loads((ROOT / "graded-stories.json").read_text())
    translations = {}
    assert len(books) == 2
    for name, book in zip(["neighborhood-secret", "first-solo-trip"], books):
        manifest, spine, toc = [], [], []
        with zipfile.ZipFile(ROOT / (name + ".epub"), "w") as archive:
            write(archive, "mimetype", "application/epub+zip")
            write(archive, "META-INF/container.xml", '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>')
            for index, chapter in enumerate(book["chapters"]):
                title = html.escape(chapter["title"])
                paragraphs = "".join("<p>" + html.escape(chinese) + "</p>" for chinese, _ in chapter["lines"])
                write(archive, f"OEBPS/ch{index}.xhtml", f'<?xml version="1.0" encoding="utf-8"?><html xmlns="http://www.w3.org/1999/xhtml" lang="zh-CN" xml:lang="zh-CN"><head><title>{title}</title></head><body><h1>{title}</h1>{paragraphs}</body></html>')
                manifest.append(f'<item id="ch{index}" href="ch{index}.xhtml" media-type="application/xhtml+xml"/>')
                spine.append(f'<itemref idref="ch{index}"/>')
                toc.append(f'<navPoint id="n{index}" playOrder="{index + 1}"><navLabel><text>{title}</text></navLabel><content src="ch{index}.xhtml"/></navPoint>')
                translations.update(chapter["lines"])
            uid = "amgi-original-" + name + "-v1"
            title = html.escape(book["title"])
            description = html.escape(book["english"])
            write(archive, "OEBPS/content.opf", f'<?xml version="1.0" encoding="utf-8"?><package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="book-id"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="book-id">{uid}</dc:identifier><dc:title>{title} · {book["level"]}</dc:title><dc:creator>Amgi Original Graded Readers</dc:creator><dc:language>zh-CN</dc:language><dc:description>{description}. Original learner story; approximate six-level HSK difficulty.</dc:description></metadata><manifest><item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>{"".join(manifest)}</manifest><spine toc="ncx">{"".join(spine)}</spine></package>')
            write(archive, "OEBPS/toc.ncx", f'<?xml version="1.0" encoding="utf-8"?><ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1"><head><meta name="dtb:uid" content="{uid}"/></head><docTitle><text>{title}</text></docTitle><navMap>{"".join(toc)}</navMap></ncx>')
    (ROOT / "reading-translations.json").write_text(json.dumps(translations, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
