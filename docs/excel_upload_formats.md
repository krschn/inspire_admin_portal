# Excel Upload Formats

This document describes the expected Excel formats for batch uploading talks.

## Standard Format

The default format for uploading talks to the admin portal.

### Column Structure

| Column | Header | Required | Description |
|--------|--------|----------|-------------|
| A (0) | Date | Yes | Date and time of the talk |
| B (1) | Title | Yes | Talk title |
| C (2) | Description | No | Talk description/abstract |
| D (3) | Speakers | No | JSON array of speaker objects |
| E (4) | Live Link | No | URL for live stream |
| F (5) | Duration | No | Duration (e.g., "45 min", "1 hour") |
| G (6) | Track | No | Track number (integer) |
| H (7) | Venue | No | Room/venue name |

### Date Formats Supported

The parser accepts multiple date formats:

**With Time:**
- `2024-01-15 14:30` (yyyy-MM-dd HH:mm)
- `01/15/2024 14:30` (MM/dd/yyyy HH:mm)
- `2024-01-15 2:30 PM` (yyyy-MM-dd h:mm AM/PM)
- `01/15/2024 2:30 PM` (MM/dd/yyyy h:mm AM/PM)
- `2024-01-15T14:30:00` (ISO 8601)

**Date Only** (defaults to 09:00):
- `2024-01-15` (yyyy-MM-dd)
- `01/15/2024` (MM/dd/yyyy)
- `01-15-2024` (MM-dd-yyyy)
- Native Excel date cells

### Speakers JSON Format

The Speakers column expects a JSON array of objects:

```json
[
  {"name": "John Doe", "image": "https://example.com/john.jpg"},
  {"name": "Jane Smith", "image": "https://example.com/jane.jpg"}
]
```

**Fields:**
- `name` (required): Speaker's full name
- `image` (optional): URL to speaker's profile image

**Examples:**
- Single speaker: `[{"name": "John Doe", "image": ""}]`
- Multiple speakers: `[{"name": "John Doe", "image": ""}, {"name": "Jane Smith", "image": ""}]`
- Empty: `[]` or leave cell blank

### Example Data

| Date | Title | Description | Speakers | Live Link | Duration | Track | Venue |
|------|-------|-------------|----------|-----------|----------|-------|-------|
| 2024-03-15 09:00 | Opening Keynote | Welcome to the conference | [{"name": "Jane Doe", "image": ""}] | https://live.example.com/1 | 60 min | 1 | Main Hall |
| 2024-03-15 10:30 | Building APIs | Learn REST API design | [{"name": "John Smith", "image": ""}] | | 45 min | 2 | Room A |
| 2024-03-15 10:30 | Data Engineering | Big data patterns | [{"name": "Alice", "image": ""}, {"name": "Bob", "image": ""}] | | 45 min | 3 | Room B |

---

## DDD 2025 Format

Format for DDD Melbourne 2025 conference exports.

### Column Structure

| Column | Header | Required | Description |
|--------|--------|----------|-------------|
| A (0) | ID | No | Internal ID (ignored) |
| B (1) | Talk Title | Yes | Talk title |
| C (2) | Name | No | Submitter name (ignored) |
| D (3) | Speaker Names | No | Comma-separated speaker names |
| E (4) | Talk Description | No | Talk description/abstract |
| F (5) | Status | No | Submission status (ignored) |
| G (6) | Track | No | Track with description (e.g., "Track 7 - Data") |
| H (7) | Talk Type | No | Duration/type (e.g., "45 min", "Keynote") |
| I (8) | Start Time | Yes* | Scheduled date/time |
| J (9) | Business Area | No | Venue/room |

*Rows without a valid Start Time are automatically filtered out (not imported).

### Key Differences from Standard Format

1. **Speaker Names**: Comma-separated text instead of JSON
   - Example: `John Doe, Jane Smith, Bob Wilson`

2. **Track**: Extracts number from descriptive text
   - `Track 7 - Data` → `7`
   - `Track 1 - General` → `1`

3. **Start Time Filtering**: Rows with empty, "None", "N/A", or "TBA" are skipped
   - This filters out unscheduled talks (e.g., Virtual Stage submissions)

4. **No Live Link**: The format doesn't include live stream URLs

### Example Data

| ID | Talk Title | Name | Speaker Names | Talk Description | Status | Track | Talk Type | Start Time | Business Area |
|----|-----------|------|---------------|------------------|--------|-------|-----------|------------|---------------|
| 1 | Building Microservices | John | John Doe | Learn about microservices | Confirmed | Track 1 - General | 45 min | 2024-03-15 09:00 | Main Hall |
| 2 | Data Pipelines | Jane | Jane Smith, Bob Wilson | Big data patterns | Confirmed | Track 7 - Data | 45 min | 2024-03-15 10:30 | Room A |
| 3 | Virtual Talk | Alice | Alice Brown | Some topic | Submitted | Track 2 - Web | 10 min | None | Virtual Stage |

In this example, row 3 would be **skipped** because Start Time is "None".

---

## Validation Rules

Both formats apply these validation rules:

1. **Title is required** - Rows without a title generate an error
2. **Valid date is required** - Rows without a parseable date generate an error (Standard) or are skipped (DDD 2025)
3. **Empty rows are skipped** - Completely empty rows are ignored
4. **Track defaults to 0** - If track cannot be parsed as a number

## Upload Behavior

- **New talks**: Created with auto-generated IDs
- **Existing talks**: Updated if a talk with the same title and date (same day) already exists
- **Errors**: Collected and displayed in the upload summary dialog
