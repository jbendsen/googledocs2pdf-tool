#!/usr/bin/env python3
import sys, io
from pathlib import Path

# Dependencies:
#   pip install pypdf reportlab
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase.pdfmetrics import stringWidth

def make_number_overlay(text, width, height, margin_mm=12, font="Helvetica", size=10):
    """Create a single-page PDF in memory with the number in the bottom-right corner."""
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(width, height))
    # margin in points (1 pt = 1/72 inch). 1 mm ≈ 2.83465 pt
    margin = margin_mm * 2.83465
    text_width = stringWidth(text, font, size)
    x = width - margin - text_width
    y = margin  # bottom
    c.setFont(font, size)
    c.drawString(x, y, text)
    c.showPage()
    c.save()
    buf.seek(0)
    return PdfReader(buf).pages[0]

def number_pdf(input_path, output_path):
    reader = PdfReader(input_path)
    writer = PdfWriter()

    for i, page in enumerate(reader.pages, start=1):
        # Add page unchanged on page 1
        if i == 1:
            writer.add_page(page)
            continue

        # Use the page's own size (keeps A4 if it already is A4)
        width = float(page.mediabox.width)
        height = float(page.mediabox.height)

        overlay = make_number_overlay(str(i), width, height)

        # Merge the overlay on top of the page (without re-rendering the page)
        try:
            page.merge_page(overlay)            # pypdf ≥ 3.x
        except Exception:
            page.mergePage(overlay)             # PyPDF2 fallback

        writer.add_page(page)

    with open(output_path, "wb") as f:
        writer.write(f)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Use: number_pdf.py INPUT.pdf OUTPUT.pdf")
        sys.exit(1)
    number_pdf(Path(sys.argv[1]), Path(sys.argv[2]))
    print(f"Wrote file: {sys.argv[2]}")
