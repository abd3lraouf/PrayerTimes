# Multi-Language READMEs Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create per-language README files with full translated content, language selector links, and images from `art/<lang>/`.

**Architecture:** One README per language (README.md for English, README.ar.md, README.id.md, README.fa.md, README.ur.md). Each has a language selector line at the top, logo image, screenshot collage, and fully translated content.

**Tech Stack:** Markdown only.

---

### Task 1: Update README.md (English)

**Files:**
- Modify: `README.md`

**Step 1:** Add language selector as the very first line. Update image paths from `screenshots/output/` to `art/en/`. Remove non-English screenshot collages (ar, fa, ur, id). Keep only English logo + screenshot.

Language selector format:
```
**English** | [العربية](README.ar.md) | [Indonesia](README.id.md) | [فارسی](README.fa.md) | [اردو](README.ur.md)
```

**Step 2:** Verify the file renders correctly.

**Step 3:** Commit: `docs: add language selector to README and update image paths`

---

### Task 2: Create README.ar.md (Arabic)

**Files:**
- Create: `README.ar.md`

**Step 1:** Write full Arabic translation of README.md with:
- Language selector (Arabic bolded, others linked)
- Logo from `art/ar/logo.png`
- Screenshot from `art/ar/screenshots.png`
- All sections translated to Arabic

**Step 2:** Commit: `docs: add Arabic README`

---

### Task 3: Create README.id.md (Indonesian)

**Files:**
- Create: `README.id.md`

**Step 1:** Write full Indonesian translation with same structure.

**Step 2:** Commit: `docs: add Indonesian README`

---

### Task 4: Create README.fa.md (Persian)

**Files:**
- Create: `README.fa.md`

**Step 1:** Write full Persian translation with same structure.

**Step 2:** Commit: `docs: add Persian README`

---

### Task 5: Create README.ur.md (Urdu)

**Files:**
- Create: `README.ur.md`

**Step 1:** Write full Urdu translation with same structure.

**Step 2:** Commit: `docs: add Urdu README`
