# Import INTERLIS Survey Details

Scripts to import survey observation details from INTERLIS VSA-KEK 2020 (LV95) XML files into existing surveys in InfoAsset Manager.

Based on a client support query where INTERLIS XML Manhole Survey and CCTV Survey data needed to be imported into surveys whose header records had already been created.

## Prerequisites

Survey header records must already exist in InfoAsset Manager before running these scripts. The `REF` attribute from the `UntersuchungRef` element in each observation is used to match against Survey IDs in the database — this value corresponds to the `TID` of the parent `VSA_KEK_2020_LV95.KEK.Untersuchung` (Survey Header) element.

## Scripts

### [UI-ImportINTERLISManholeSurveyDetails.rb](./UI-ImportINTERLISManholeSurveyDetails.rb)

Imports `VSA_KEK_2020_LV95.KEK.Normschachtschaden` observation elements into the Manhole Survey (`cams_manhole_survey`) details table.

### [UI-ImportINTERLISCCTVSurveyDetails.rb](./UI-ImportINTERLISCCTVSurveyDetails.rb)

Imports `VSA_KEK_2020_LV95.KEK.Kanalschaden` observation elements into the CCTV Survey (`cams_cctv_survey`) details table.

## Usage

When the script is run, a file selection dialog opens to choose the INTERLIS XML file. The script matches surveys by ID and appends observation details to any existing records in the details table. Once all details for a survey are written, the `video_file_in` field on the parent survey record is updated with the associated video filename.

Observations are sorted by `Distanz` (ascending) then `Videozaehlerstand` (ascending) before being written.

## File Attachments

The `VSA_KEK_2020_LV95.KEK.Datei` section is read to resolve image and video filenames:

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
| `Verbindung` | `joint` | `"ja"` → `true`, otherwise `false` |
| `Videozaehlerstand` | `video_no2` | |
| `Distanz` | `distance` | |
| `KanalSchadencode` | `code` | |
| `Quantifizierung1` | `diameter` | |
| `Quantifizierung2` | `intrusion` | |
| `SchadenlageAnfang` | `clock_at` | `"12"` → `"0"` |
| `SchadenlageEnde` | `clock_to` | `"12"` → `"0"` |
| `Datei.Bezeichnung` (Foto) | `photo_no` | Matched via observation `TID` |
| `Datei.Bezeichnung` (digitales_Video) | `video_file` | Matched via survey `REF` |
| `TID` | `characterisation3` | Stores the XML observation identifier |
| `Datei.Bezeichnung` (digitales_Video) | `video_file_in` (survey) | Written to parent survey record |

> **Note:** The `Letzte_Aenderung` element is parsed from the XML but is not currently written to any field.
