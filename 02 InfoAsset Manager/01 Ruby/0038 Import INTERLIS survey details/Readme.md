# Import INTERLIS Survey Details

Scripts to import survey observation details from INTERLIS VSA-KEK XML files into existing surveys in InfoAsset Manager.

Based on a client support query where INTERLIS XML Manhole Survey and CCTV Survey data needed to be imported into surveys whose header records had already been created.

## Prerequisites

Survey header records must already exist in InfoAsset Manager before running these scripts. The `REF` attribute from the `UntersuchungRef` element in each observation is used to match against Survey IDs in the database — this value corresponds to the `TID` of the parent survey header element.

## XML Version Compatibility

The scripts match observation elements by suffix rather than by a hardcoded prefix, so they work with multiple VSA-KEK schema versions:

| Schema version | Observation element | File element |
|---|---|---|
| `VSA_KEK_2020_LV95` | `VSA_KEK_2020_LV95.KEK.Kanalschaden` | `VSA_KEK_2020_LV95.KEK.Datei` |
| `VSA_KEK` | `VSA_KEK.KEK.Kanalschaden` | `VSA_KEK.KEK.Datei` |
| Any future prefix | `*.KEK.Kanalschaden` | `*.KEK.Datei` |

## Scripts

### [UI-ImportINTERLISManholeSurveyDetails.rb](./UI-ImportINTERLISManholeSurveyDetails.rb)

Imports `.KEK.Normschachtschaden` observation elements into the Manhole Survey (`cams_manhole_survey`) details table.

### [UI-ImportINTERLISCCTVSurveyDetails.rb](./UI-ImportINTERLISCCTVSurveyDetails.rb)

Imports `.KEK.Kanalschaden` observation elements into the CCTV Survey (`cams_cctv_survey`) details table.

## Usage

When the script is run, a file selection dialog opens to choose the INTERLIS XML file. The script matches surveys by ID and appends observation details to any existing records in the details table. Once all details for a survey are written, the `video_file_in` field on the parent survey record is updated with the associated video filename.

Observations are sorted by `Distanz` (ascending) then `Videozaehlerstand` (ascending) before being written.

## File Attachments

The `.KEK.Datei` section is read to resolve image and video filenames:

- `Foto` entries — the `Bezeichnung` value is matched to observations where `Objekt` equals the observation `TID`.
- `digitales_Video` entries — the `Bezeichnung` value is matched to observations where `Objekt` equals the survey `REF` (i.e. one video filename per survey).

## Field Mappings

### Manhole Survey (`Normschachtschaden` → `cams_manhole_survey` details)

| INTERLIS Field | InfoAsset Manager Field | Notes |
|---|---|---|
| `Anmerkung` | `remarks` | |
| `Streckenschaden` | `cd` | `A` → `S`, `B` → `F` |
| `Verbindung` | `joint` | `"ja"` → `true`, otherwise `false` |
| `Videozaehlerstand` | `video_no2` | |
| `Distanz` | `distance` | |
| `SchachtSchadencode` | `code` | |
| `Quantifizierung1` | `quant1` | |
| `Quantifizierung2` | `quant2` | |
| `Schachtbereich` | `descriptive_location` | |
| `SchadenlageAnfang` | `clock_at` | `"12"` → `"0"` |
| `SchadenlageEnde` | `clock_to` | `"12"` → `"0"` |
| `Datei.Bezeichnung` (Foto) | `photo_no` | Matched via observation `TID` |
| `Datei.Bezeichnung` (digitales_Video) | `video_file` | Matched via survey `REF` |
| `Datei.Bezeichnung` (digitales_Video) | `video_file_in` (survey) | Written to parent survey record |

### CCTV Survey (`Kanalschaden` → `cams_cctv_survey` details)

| INTERLIS Field | InfoAsset Manager Field | Notes |
|---|---|---|
| `Anmerkung` | `remarks` | |
| `Streckenschaden` | `cd` | `A` → `S`, `B` → `F` |
| `Verbindung` | `joint` | `"ja"` → `true`, otherwise `false`. Also forced `true` for BAJ joint codes regardless of `Verbindung` value — see [Joint Flag Rules](#joint-flag-rules) |
| `Videozaehlerstand` | `video_no2` | |
| `Distanz` | `distance` | |
| `KanalSchadencode` (chars 1–3) | `code` | First 3 characters only |
| `KanalSchadencode` (char 4) | `characterisation1` | Band — only set when code is longer than 3 characters |
| `KanalSchadencode` (char 5) | `characterisation2` | Material — only set when code is longer than 4 characters |
| `Quantifizierung1` | `percentage` | For percentage codes only — see [Quantifizierung Mapping](#quantifizierung-mapping) |
| `Quantifizierung1` | `diameter` | For all other codes |
| `Quantifizierung2` | `intrusion` | For all non-percentage codes |
| `SchadenlageAnfang` | `clock_at` | `"12"` → `"0"` |
| `SchadenlageEnde` | `clock_to` | `"12"` → `"0"`. When both values resolve to `"0"`, `clock_to` is corrected to `"12"` to represent a full-circumference defect |
| `Datei.Bezeichnung` (Foto) | `photo_no` | Matched via observation `TID` |
| `Datei.Bezeichnung` (digitales_Video) | `video_file` | Matched via survey `REF` |
| `TID` | `characterisation3` | Stores the XML observation identifier |
| `Datei.Bezeichnung` (digitales_Video) | `video_file_in` (survey) | Written to parent survey record |

> **Note:** The `Letzte_Aenderung` element is parsed from the XML but is not currently written to any field.

---

## Business Rules (CCTV Script)

### Joint Flag Rules

`joint` is set to `true` in two cases:

1. The `Verbindung` XML field is `"ja"`.
2. The observation code (first 3 characters) is one of the BAJ displaced joint codes: `BAJA`, `BAJB`, `BAJC`.

Rule 2 corrects cases where an operator recorded `Verbindung = "nein"` despite the defect code clearly describing a joint defect.

### Full-Circumference Clock Correction

Clock positions are stored as values `0`–`12`. The value `12` in the XML is normalised to `0` on import (both represent 12 o'clock). When both `clock_at` and `clock_to` resolve to `"0"` after this normalisation, the defect wraps the full pipe circumference — `clock_to` is corrected to `"12"` so that InfoAsset Manager interprets it as `0–12` (full circumference) rather than `0–0` (point defect at 12 o'clock).

### Quantifizierung Mapping

`Quantifizierung1` and `Quantifizierung2` represent different value types depending on the observation code:

| Code type | `Quantifizierung1` → IAM field | `Quantifizierung2` → IAM field |
|---|---|---|
| Percentage codes (listed below) | `percentage` (fraction) | _(not set)_ |
| All other codes | `diameter` (mm) | `intrusion` (mm / distance) |

Codes mapped to `percentage`:

```
BAAA  BAA8
BAI   BAIAA  BAIAB  BAIAC  BAIAG  BAIAZ
BAJA
BAKAA  BAKAB  BAKODA  BAKODB  BAKOE  BAKOEO  BAKED  BAKEF
BAKJ   BAKJA  BAKJB   BAKJC
BBAA  BBAB  BBAC  BBAD  BBAE  BBAF  BBAG  BBAH  BBAI  BBAJ  BBAK  BBAL  BBAM  BBAN  BBAO  BBAP  BBAZ
BBBA  BBBB  BBBC  BBBD  BBBE  BBBF  BBBG  BBBH  BBBI  BBBJ  BBBK  BBBL  BBBM  BBBN  BBBO  BBBP  BBBZ
BCDA  BCDB  BCDC
```
