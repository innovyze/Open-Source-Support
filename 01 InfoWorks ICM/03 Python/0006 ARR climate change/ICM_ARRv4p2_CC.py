import shutil
import os
import zipfile
import tkinter as tk
from tkinter import filedialog, ttk
import pandas as pd
import io
import re

# Constants for SSP options and file/section names
SSP_OPTIONS = ["SSP1-2.6", "SSP2-4.5", "SSP3-7.0", "SSP5-8.5"]
SECTION_END_PREFIX = "[END_"
NUMERIC_PATTERN = re.compile(r"[-+]?(?:\d+\.\d*|\.\d+|\d+)")
ARR_DATA_HUB_FILENAME = "ArrDataHub.txt"
BOM_IFDS_FILENAME = "BomIfds.csv"

# ---------------- UI ----------------
DESIGN_YEARS = ["2030", "2040", "2050", "2060", "2070", "2080", "2090", "2100"]


def _build_ssp_selector(parent):
    tk.Label(parent, text="Select Shared Socioeconomic Pathway (SSP)").pack(pady=5)
    ssp_var = tk.StringVar()
    dropdown = ttk.Combobox(parent, textvariable=ssp_var, values=SSP_OPTIONS, state="readonly", width=20)
    dropdown.pack(pady=5)
    dropdown.current(0)
    return ssp_var


def _build_year_selector(parent):
    tk.Label(parent, text="Select Design Year").pack(pady=5)
    year_var = tk.StringVar()
    dropdown = ttk.Combobox(parent, textvariable=year_var, values=DESIGN_YEARS, state="readonly", width=10)
    dropdown.pack(pady=5)
    dropdown.current(0)
    return year_var


def get_user_choices():
    root = tk.Tk()
    root.title("Select Options")
    ssp_var = _build_ssp_selector(root)
    year_var = _build_year_selector(root)
    tk.Button(root, text="Submit", command=root.quit).pack(pady=10)
    root.mainloop()
    ssp, year = ssp_var.get(), year_var.get()
    root.destroy()
    return ssp, year

# ---------------- Parsers ----------------
def _extract_value_from_parts(parts, year, ssp, target_idx):
    """Extract numeric value from a row (parts) for given year/SSP; used by loss and temperature parsers."""
    if not parts or parts[0] != str(year):
        return None
    if target_idx is None:
        try:
            pos = SSP_OPTIONS.index(ssp)
            candidate = pos + 1
        except ValueError:
            candidate = 1
        if candidate >= len(parts):
            return None
        val_str = parts[candidate]
    else:
        val_str = parts[target_idx] if target_idx < len(parts) else parts[-1]
    m = NUMERIC_PATTERN.search(val_str)
    return float(m.group()) if m else None


def _parse_rainfall_row(parts, year):
    """Extract up to 10 numeric values from a rainfall row for the given year."""
    if not parts or parts[0] != str(year):
        return None
    vals = []
    for tok in parts[1:]:
        m = NUMERIC_PATTERN.search(tok)
        if m:
            vals.append(float(m.group()))
    return vals[:10] if vals else None


def parse_rainfall_ccf(txt_content, ssp, year):
    """Parse rainfall CCF list (10 values) from the [SSP...] section for the chosen year."""
    lines = txt_content.splitlines()
    inside = False
    for line in lines:
        if line.strip() == f"[{ssp}]":
            inside = True
            continue
        if not inside:
            continue
        if line.startswith(SECTION_END_PREFIX):
            break
        parts = [p.strip() for p in line.split(",")]
        result = _parse_rainfall_row(parts, year)
        if result is not None:
            return result
    return None

def _parse_section_table(txt_content, section_header, ssp, year):
    """Parse a [SectionName] table and return the numeric value for the given ssp/year row."""
    lines = txt_content.splitlines()
    inside = False
    header = None
    target_idx = None
    for line in lines:
        if line.strip() == section_header:
            inside = True
            header = None
            target_idx = None
            continue
        if not inside:
            continue
        if line.startswith(SECTION_END_PREFIX):
            break
        if header is None:
            if line.strip():
                header = [h.strip() for h in line.split(",")]
                target_idx = next((j for j, h in enumerate(header) if ssp in h), None)
            continue
        parts = [p.strip() for p in line.split(",")]
        val = _extract_value_from_parts(parts, year, ssp, target_idx)
        if val is not None:
            return val
    return None


def parse_loss_factor_table(txt_content, section_name, ssp, year):
    """Parse [Climate_Change_INITIAL_LOSS] or [Climate_Change_CONTINUING_LOSS] table."""
    return _parse_section_table(txt_content, f"[{section_name}]", ssp, year)


def parse_temperature_change(txt_content, ssp, year):
    """Parse TEMPERATURE_CHANGES table and return the temperature change value for SSP/year."""
    return _parse_section_table(txt_content, "[TEMPERATURE_CHANGES]", ssp, year)

# ---------------- Apply rainfall factors ----------------
DURATION_MAP = {
    1.0: 0, 1.5: 1, 2.0: 2, 3.0: 3, 4.5: 4,
    6.0: 5, 9.0: 6, 12.0: 7, 18.0: 8, 24.0: 9,
}
DURATIONS_SORTED = sorted(DURATION_MAP.keys())


def _factor_for_duration(dur_hr, factors):
    """Return the interpolation factor for a given duration in hours."""
    if dur_hr in DURATION_MAP:
        return factors[DURATION_MAP[dur_hr]]
    if dur_hr < 1.0:
        return factors[0]
    if dur_hr > 24.0:
        return factors[-1]
    lower = max(d for d in DURATIONS_SORTED if d < dur_hr)
    upper = min(d for d in DURATIONS_SORTED if d > dur_hr)
    li, ui = DURATION_MAP[lower], DURATION_MAP[upper]
    f_lower, f_upper = factors[li], factors[ui]
    return f_lower + (f_upper - f_lower) * ((dur_hr - lower) / (upper - lower))


def _scale_row_values(df, idx, row, factor):
    """Scale numeric columns in row by factor; skip Duration columns."""
    for col in df.columns:
        if col in ("Duration", "Duration in min"):
            continue
        try:
            val = float(row[col])
            df.at[idx, col] = round(val * factor, 2)
        except (ValueError, TypeError):
            pass


def apply_factors_to_csv(csv_bytes, factors):
    """
    Adjust BomIfds.csv rainfall depths according to provided factors.
    factors: list of 10 floats: [<=1h,1.5h,2h,3h,4.5h,6h,9h,12h,18h,>=24h]
    """
    text = csv_bytes.decode("utf-8").splitlines()
    header_index = next(i for i, l in enumerate(text) if l.startswith("Duration,Duration in min"))
    header_lines = text[:header_index]
    data_lines = text[header_index:]
    df = pd.read_csv(io.StringIO("\n".join(data_lines)))

    for idx, row in df.iterrows():
        dur_hr = float(row["Duration in min"]) / 60.0
        factor = _factor_for_duration(dur_hr, factors)
        _scale_row_values(df, idx, row, factor)

    out = io.StringIO()
    for line in header_lines:
        out.write(line + "\n")
    df.to_csv(out, index=False)
    return out.getvalue().encode("utf-8")

# ---------------- Apply loss factors ----------------
def _apply_loss_line_factor(line, factor):
    """Replace first number in line with value scaled by factor; return updated line."""
    m = NUMERIC_PATTERN.search(line)
    if not m or not factor:
        return line
    orig = float(m.group())
    newv = round(orig * factor, 2)
    return line[:m.start()] + str(newv) + line[m.end():]


def _process_losses_line(line, inside_losses, init_factor, cont_factor):
    """Process one line inside [LOSSES]; return (updated_line, still_inside_losses)."""
    stripped = line.strip()
    if stripped.lower().startswith("storm initial losses"):
        line = _apply_loss_line_factor(line, init_factor)
    elif stripped.lower().startswith("storm continuing losses"):
        line = _apply_loss_line_factor(line, cont_factor)
    return line, inside_losses


def apply_factors_to_losses(txt_content, init_factor, cont_factor):
    """Update [LOSSES] section values."""
    lines = txt_content.splitlines()
    new_lines = []
    inside_losses = False
    for line in lines:
        stripped = line.strip()
        if stripped.upper() == "[LOSSES]":
            inside_losses = True
            new_lines.append(line)
            continue
        if inside_losses and stripped.startswith("[") and not stripped.upper().startswith("[LOSSES"):
            inside_losses = False
            new_lines.append(line)
            continue
        if inside_losses:
            line, _ = _process_losses_line(line, inside_losses, init_factor, cont_factor)
        new_lines.append(line)
    return "\n".join(new_lines)

# ---------------- Main ----------------
SKIP_ZIP_ENTRIES = (BOM_IFDS_FILENAME, ARR_DATA_HUB_FILENAME, "old_BomIfds.csv", "old_ArrDataHub.txt", "adjustment_info.txt")


def _ask_zip_path():
    root = tk.Tk()
    root.withdraw()
    path = filedialog.askopenfilename(title="Select a ZIP file", filetypes=[("ZIP files", "*.zip")])
    root.destroy()
    return path


def _base_name_from_filename(filename):
    fname_lower = filename.lower()
    if fname_lower.endswith(".arr.zip"):
        return filename[:-8]
    if fname_lower.endswith(".zip"):
        return filename[:-4]
    base, _ = os.path.splitext(filename)
    return base


def _versioned_copy_path(folder, base, ssp, year):
    copy_path = os.path.join(folder, f"{base}_{ssp}_{year}.arr.zip")
    v = 1
    final_copy = copy_path
    while os.path.exists(final_copy):
        v += 1
        final_copy = copy_path.replace(".arr.zip", f"_v{v}.arr.zip")
    return final_copy


def _read_zip_contents(zf):
    try:
        arr_txt_bytes = zf.read(ARR_DATA_HUB_FILENAME)
    except KeyError:
        print(f"ERROR: {ARR_DATA_HUB_FILENAME} not found inside the zip.")
        return None
    try:
        original_csv = zf.read(BOM_IFDS_FILENAME)
    except KeyError:
        print(f"ERROR: {BOM_IFDS_FILENAME} not found inside the zip.")
        return None
    return arr_txt_bytes, arr_txt_bytes.decode("utf-8"), original_csv


def _write_updated_zip(zf, copy_path, arr_txt, arr_txt_bytes, original_csv, ssp, year,
                       rainfall_factors, init_loss, cont_loss, temp_change):
    temp_zip = copy_path + ".tmp"
    updated_arr_txt = apply_factors_to_losses(arr_txt, init_loss, cont_loss)
    with zipfile.ZipFile(temp_zip, "w") as new_zip:
        for item in zf.infolist():
            if item.filename in SKIP_ZIP_ENTRIES:
                continue
            new_zip.writestr(item, zf.read(item.filename))
        new_zip.writestr("old_BomIfds.csv", original_csv)
        new_zip.writestr("old_ArrDataHub.txt", arr_txt_bytes)
        if rainfall_factors is None:
            print(f"WARNING: rainfall CCFs not found for the chosen SSP/year; {BOM_IFDS_FILENAME} will not be adjusted.")
            new_zip.writestr(BOM_IFDS_FILENAME, original_csv)
        else:
            new_zip.writestr(BOM_IFDS_FILENAME, apply_factors_to_csv(original_csv, rainfall_factors))
        new_zip.writestr(ARR_DATA_HUB_FILENAME, updated_arr_txt.encode("utf-8"))
        adj_lines = [
            f"SSP: {ssp}", f"Design Year: {year}",
            f"Rainfall CCF count: {len(rainfall_factors) if rainfall_factors else 'N/A'}",
            f"Initial loss factor: {init_loss}", f"Continuing loss factor: {cont_loss}",
            f"Temperature change (°C): {temp_change}"
        ]
        new_zip.writestr("adjustment_info.txt", ("\n".join(adj_lines)).encode("utf-8"))
    return temp_zip, updated_arr_txt


def copy_and_update_zip():
    file_path = _ask_zip_path()
    if not file_path:
        print("No file selected.")
        return

    ssp, year = get_user_choices()
    folder, filename = os.path.split(file_path)
    base = _base_name_from_filename(filename)
    copy_path = _versioned_copy_path(folder, base, ssp, year)

    shutil.copy2(file_path, copy_path)
    print(f"Copied to: {copy_path}")

    with zipfile.ZipFile(copy_path, "r") as zf:
        contents = _read_zip_contents(zf)
        if contents is None:
            return
        arr_txt_bytes, arr_txt, original_csv = contents

        rainfall_factors = parse_rainfall_ccf(arr_txt, ssp, year)
        init_loss = parse_loss_factor_table(arr_txt, "Climate_Change_INITIAL_LOSS", ssp, year)
        cont_loss = parse_loss_factor_table(arr_txt, "Climate_Change_CONTINUING_LOSS", ssp, year)
        temp_change = parse_temperature_change(arr_txt, ssp, year)

        print(f"Parsed rainfall factors count: {len(rainfall_factors) if rainfall_factors else 0}")
        print(f"Initial loss factor: {init_loss}")
        print(f"Continuing loss factor: {cont_loss}")
        print(f"Temperature change (°C): {temp_change}")

        temp_zip, updated_arr_txt = _write_updated_zip(
            zf, copy_path, arr_txt, arr_txt_bytes, original_csv, ssp, year,
            rainfall_factors, init_loss, cont_loss, temp_change)

    os.replace(temp_zip, copy_path)
    print(f"✅ Updated ARR ZIP created: {copy_path}")

    for line in updated_arr_txt.splitlines():
        low = line.lower()
        if low.startswith("storm initial losses") or low.startswith("storm continuing losses"):
            print(line)
    print(f"Temperature change for {ssp} / {year}: {temp_change} °C")

    extract_folder = copy_path[:-4]
    os.makedirs(extract_folder, exist_ok=True)
    with zipfile.ZipFile(copy_path, "r") as zf:
        zf.extractall(extract_folder)
    print(f"📂 Extracted contents to: {extract_folder}")

if __name__ == "__main__":
    copy_and_update_zip()

