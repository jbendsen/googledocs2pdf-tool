Here’s a `README.md` you can drop into the repo.

---

# Google Doc → PDF generator (and manual builder)

This project contains small shell/Python utilities to:

1. fetch a set of Google Docs from a Drive folder and export them as PDFs, and
2. merge those PDFs (in alphanumeric order) into a single PDF with page numbers.

`example.sh` shows a concrete end-to-end invocation.&#x20;

---

## 1) Prerequisites

### A. Google Cloud & auth

* A Google Cloud **project ID** (you can use an existing one).
* **Enable Drive API** on that project (Cloud Console → APIs & Services → Enable APIs → Google Drive API).
* **gcloud CLI** installed and logged in:

  ```bash
  # install gcloud (macOS via Homebrew)
  brew install --cask google-cloud-sdk

  # authenticate ADC with the required scopes
  gcloud auth application-default login \
    --scopes=https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform
  ```

  The fetch script uses the resulting access token and sets the quota project via the `X-Goog-User-Project` header.&#x20;

### B. Command-line tools

* **curl** and **jq** (used to list and filter Drive files):

  ```bash
  # macOS (Homebrew)
  brew install curl jq
  # Ubuntu/Debian
  sudo apt-get update && sudo apt-get install -y curl jq
  ```
* **qpdf** (lossless PDF merge):

  ```bash
  # macOS
  brew install qpdf
  # Ubuntu/Debian
  sudo apt-get install -y qpdf
  ```

  The merge script requires `qpdf`; it concatenates PDFs without re-rendering.&#x20;

### C. Python for page numbering

* **Python 3** plus a small virtual environment with two libs:

  ```bash
  python3 -m venv .venv
  source .venv/bin/activate
  pip install --upgrade pip
  pip install pypdf reportlab
  ```

  The merge script activates `.venv` and calls `number_pdf.py` to overlay page numbers (page 1 is skipped).&#x20;

---

## 2) Scripts overview

* `getGoogleDocsAsPDFs.sh`
  Exports Google Docs from a Drive **folder ID** to PDFs.
  It filters files whose names match `^[0-9]{2} - .+` (e.g., `01 - Intro`, `02 - …`).
  Usage (params): `FOLDER_ID`, `GOOGLE_PROJECT`, `[OUTPUT_DIR]`.&#x20;

* `mergePDFs.sh`
  Merges all PDFs from an input directory in **alphanumeric order** into `merged.pdf`, then runs `number_pdf.py` to produce a numbered final PDF. Usage (params): `[INPUT_DIR] [TEMP_OUTPUT_FILE] [FINAL_OUTPUT_FILE]`.&#x20;

* `number_pdf.py`
  Adds bottom-right page numbers to a PDF (skips page 1). Called by `mergePDFs.sh`.

* `example.sh`
  Minimal example pipeline that calls the fetch and merge scripts.&#x20;

---

## 3) How to use

### A. Quick start (one-liner build)

From the repo root:

```bash
# 1) (first time) set up Python venv for numbering
python3 -m venv .venv && source .venv/bin/activate && pip install -U pip && pip install pypdf reportlab

# 2) run the example build
./example.sh
```

What it does (per the script):

* Fetches all matching Google Docs from the given **Drive folder ID** into `./output/`
* Merges them into `./output/merged.pdf` and writes numbered final PDF to `./final.pdf`&#x20;

> Tip: open `example.sh` and replace the sample **folder ID** and **project ID** with your own.&#x20;

### B. Fetch Google Docs as PDFs (standalone)

```bash
# Syntax:
# ./getGoogleDocsAsPDFs.sh <FOLDER_ID> <GOOGLE_PROJECT_ID> [OUTPUT_DIR]

./getGoogleDocsAsPDFs.sh 1YourFolderIdHere my-gcp-project output
```

* Prompts browser login (if needed) and obtains an access token.
* Lists files in the folder, filters **Google Docs** whose names look like `NN - Title` (NN = two digits), and exports each to PDF into `output/`.
* Uses the quota project header `X-Goog-User-Project: <GOOGLE_PROJECT_ID>`.&#x20;

### C. Merge PDFs and add page numbers (standalone)

```bash
# Syntax:
# ./mergePDFs.sh [INPUT_DIR] [TEMP_OUTPUT_FILE] [FINAL_OUTPUT_FILE]

# Example:
./mergePDFs.sh ./output ./output/merged.pdf ./final.pdf
```

* Sorts all `*.pdf` in `INPUT_DIR` **alphanumerically** and concatenates them with `qpdf` into the temp output.
* Activates `.venv` and runs `number_pdf.py` to create the final, numbered PDF.&#x20;

---

## 4) Notes & troubleshooting

* **Scopes**: the auth call must include `drive.readonly` and `cloud-platform` scopes (already in the fetch script).&#x20;
* **Quota/403**: ensure you pass a real `GOOGLE_PROJECT_ID`; the script sets `X-Goog-User-Project` so calls are billed/quota-tracked to that project.&#x20;
* **File filter**: only Docs named like `NN - Something` are exported; tweak the regex in `getGoogleDocsAsPDFs.sh` if needed.&#x20;
* **Ordering**: merge is by **filename** (C-locale bytewise). Prefixing with numbers (`01`, `02`, …) guarantees the desired order.&#x20;
* **Page numbers**: first page is intentionally unnumbered; edit `number_pdf.py` if you want different behavior. (Called by `mergePDFs.sh`.)&#x20;

---

## 5) Example end-to-end session

```bash
# one-time setup
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install pypdf reportlab

# auth (if not already done)
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/cloud-platform

# fetch
./getGoogleDocsAsPDFs.sh 1YourFolderIdHere my-gcp-project output

# merge + number
./mergePDFs.sh ./output ./output/merged.pdf ./final.pdf
```

You should end up with:

* Individual PDFs in `./output/`
* A merged intermediate at `./output/merged.pdf`
* The final numbered PDF at `./final.pdf`&#x20;

---
