import shutil
import os
import zipfile
import tkinter as tk
from tkinter import filedialog, ttk
import pandas as pd
import io
import re

# ---------------- UI ----------------
def get_user_choices():
    root = tk.Tk()
    root.title("Select Options")

    tk.Label(root, text="Select Shared Socioeconomic Pathway (SSP)").pack(pady=5)
    ssp_var = tk.StringVar()
    ssp_dropdown = ttk.Combobox(
        root,
        textvariable=ssp_var,
        values=["SSP1-2.6", "SSP2-4.5", "SSP3-7.0", "SSP5-8.5"],
        state="readonly",
        width=20
    )
    ssp_dropdown.pack(pady=5)
    ssp_dropdown.current(0)

    tk.Label(root, text="Select Design Year").pack(pady=5)
    year_var = tk.StringVar()
    year_dropdown = ttk.Combobox(
        root,
        textvariable=year_var,
        values=["2030","2040","2050","2060","2070","2080","2090","2100"],
        state="readonly",
        width=10
    )
    year_dropdown.pack(pady=5)
    year_dropdown.current(0)

    def submit():
        root.quit()

    tk.Button(root, text="Submit", command=submit).pack(pady=10)
    root.mainloop()
    ssp, year = ssp_var.get(), year_var.get()
    root.destroy()
    return ssp, year

# ---------------- Parsers ----------------
def parse_rainfall_ccf(txt_content, ssp, year):
    """Parse rainfall CCF list (10 values) from the [SSP...] section for the chosen year."""
    lines = txt_content.splitlines()
    inside = False
    for line in lines:
        if line.strip() == f"[{ssp}]":
            inside = True
            continue
        if inside:
            if line.startswith("[END_"):
                break
            parts = [p.strip() for p in line.split(",")]
            if len(parts) and parts[0] == str(year):
                vals = []
                for tok in parts[1:]:
                    m = re.search(r"[-+]?\d*\.\d+|\d+", tok)
                    if m:
                        vals.append(float(m.group()))
                return vals[:10] if vals else None
    return None

def parse_loss_factor_table(txt_content, section_name, ssp, year):
    """Parse [Climate_Change_INITIAL_LOSS] or [Climate_Change_CONTINUING_LOSS] table."""
    lines = txt_content.splitlines()
    inside = False
    header = None
    target_idx = None
    for line in lines:
        if line.strip() == f"[{section_name}]":
            inside = True
            header = None
            target_idx = None
            continue
        if inside:
            if line.startswith("[END_"):
                break
            if header is None:
                if line.strip() == "":
                    continue
                header = [h.strip() for h in line.split(",")]
                for j, h in enumerate(header):
                    if ssp in h:
                        target_idx = j
                        break
                continue
            parts = [p.strip() for p in line.split(",")]
            if parts and parts[0] == str(year):
                if target_idx is None:
                    known = ["SSP1-2.6", "SSP2-4.5", "SSP3-7.0", "SSP5-8.5"]
                    try:
                        pos = known.index(ssp)
                        candidate = pos + 1
                    except ValueError:
                        candidate = 1
                    if candidate < len(parts):
                        val_str = parts[candidate]
                    else:
                        return None
                else:
                    val_str = parts[target_idx] if target_idx < len(parts) else parts[-1]
                m = re.search(r"[-+]?\d*\.\d+|\d+", val_str)
                return float(m.group()) if m else None
    return None

def parse_temperature_change(txt_content, ssp, year):
    """Parse TEMPERATURE_CHANGES table and return the temperature change value for SSP/year."""
    lines = txt_content.splitlines()
    inside = False
    header = None
    target_idx = None
    for line in lines:
        if line.strip() == "[TEMPERATURE_CHANGES]":
            inside = True
            header = None
            target_idx = None
            continue
        if inside:
            if line.startswith("[END_"):
                break
            if header is None:
                if line.strip() == "":
                    continue
                header = [h.strip() for h in line.split(",")]
                for j, h in enumerate(header):
                    if ssp in h:
                        target_idx = j
                        break
                continue
            parts = [p.strip() for p in line.split(",")]
            if parts and parts[0] == str(year):
                if target_idx is None:
                    # fallback mapping by known SSP order
                    known = ["SSP1-2.6", "SSP2-4.5", "SSP3-7.0", "SSP5-8.5"]
                    try:
                        pos = known.index(ssp)
                        candidate = pos + 1
                    except ValueError:
                        candidate = 1
                    if candidate < len(parts):
                        val_str = parts[candidate]
                    else:
                        return None
                else:
                    val_str = parts[target_idx] if target_idx < len(parts) else parts[-1]
                m = re.search(r"[-+]?\d*\.\d+|\d+", val_str)
                return float(m.group()) if m else None
    return None

# ---------------- Apply rainfall factors ----------------
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

    duration_map = {
        1.0: 0,   # <=1h
        1.5: 1,
        2.0: 2,
        3.0: 3,
        4.5: 4,
        6.0: 5,
        9.0: 6,
        12.0: 7,
        18.0: 8,
        24.0: 9   # >=24h
    }
    durations = sorted(duration_map.keys())

    for idx, row in df.iterrows():
        dur_hr = float(row["Duration in min"]) / 60.0
        if dur_hr in duration_map:
            factor = factors[duration_map[dur_hr]]
        elif dur_hr < 1.0:
            factor = factors[0]
        elif dur_hr > 24.0:
            factor = factors[-1]
        else:
            lower = max(d for d in durations if d < dur_hr)
            upper = min(d for d in durations if d > dur_hr)
            li = duration_map[lower]
            ui = duration_map[upper]
            f_lower = factors[li]
            f_upper = factors[ui]
            factor = f_lower + (f_upper - f_lower) * ((dur_hr - lower) / (upper - lower))

        for col in df.columns:
            if col not in ["Duration", "Duration in min"]:
                try:
                    val = float(row[col])
                    df.at[idx, col] = round(val * factor, 2)
                except:
                    pass

    out = io.StringIO()
    for line in header_lines:
        out.write(line + "\n")
    df.to_csv(out, index=False)
    return out.getvalue().encode("utf-8")

# ---------------- Apply loss factors ----------------
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
            if stripped.lower().startswith("storm initial losses") and init_factor:
                m = re.search(r"([-+]?\d*\.\d+|\d+)", line)
                if m:
                    orig = float(m.group())
                    newv = round(orig * init_factor, 2)
                    line = line[:m.start()] + str(newv) + line[m.end():]
            if stripped.lower().startswith("storm continuing losses") and cont_factor:
                m = re.search(r"([-+]?\d*\.\d+|\d+)", line)
                if m:
                    orig = float(m.group())
                    newv = round(orig * cont_factor, 2)
                    line = line[:m.start()] + str(newv) + line[m.end():]
        new_lines.append(line)
    return "\n".join(new_lines)

# ---------------- Main ----------------
def copy_and_update_zip():
    root = tk.Tk()
    root.withdraw()
    file_path = filedialog.askopenfilename(title="Select a ZIP file", filetypes=[("ZIP files", "*.zip")])
    root.destroy()
    if not file_path:
        print("No file selected.")
        return

    ssp, year = get_user_choices()
    folder, filename = os.path.split(file_path)
    fname_lower = filename.lower()
    if fname_lower.endswith(".arr.zip"):
        base = filename[:-8]
    elif fname_lower.endswith(".zip"):
        base = filename[:-4]
    else:
        base, _ = os.path.splitext(filename)

    copy_path = os.path.join(folder, f"{base}_{ssp}_{year}.arr.zip")
    # simple versioning
    v = 1
    final_copy = copy_path
    while os.path.exists(final_copy):
        v += 1
        final_copy = copy_path.replace(".arr.zip", f"_v{v}.arr.zip")
    copy_path = final_copy

    shutil.copy2(file_path, copy_path)
    print(f"Copied to: {copy_path}")

    with zipfile.ZipFile(copy_path, "r") as zf:
        try:
            arr_txt_bytes = zf.read("ArrDataHub.txt")
            arr_txt = arr_txt_bytes.decode("utf-8")
        except KeyError:
            print("ERROR: ArrDataHub.txt not found inside the zip.")
            return

        # parse factors
        rainfall_factors = parse_rainfall_ccf(arr_txt, ssp, year)
        init_loss = parse_loss_factor_table(arr_txt, "Climate_Change_INITIAL_LOSS", ssp, year)
        cont_loss = parse_loss_factor_table(arr_txt, "Climate_Change_CONTINUING_LOSS", ssp, year)
        temp_change = parse_temperature_change(arr_txt, ssp, year)

        print(f"Parsed rainfall factors count: {len(rainfall_factors) if rainfall_factors else 0}")
        print(f"Initial loss factor: {init_loss}")
        print(f"Continuing loss factor: {cont_loss}")
        print(f"Temperature change (°C): {temp_change}")

        try:
            original_csv = zf.read("BomIfds.csv")
        except KeyError:
            print("ERROR: BomIfds.csv not found inside the zip.")
            return

        temp_zip = copy_path + ".tmp"
        with zipfile.ZipFile(temp_zip, "w") as new_zip:
            # copy other items except the ones we will replace
            for item in zf.infolist():
                name = item.filename
                if name in ("BomIfds.csv", "ArrDataHub.txt", "old_BomIfds.csv", "old_ArrDataHub.txt", "adjustment_info.txt"):
                    continue
                new_zip.writestr(item, zf.read(name))

            # keep originals
            new_zip.writestr("old_BomIfds.csv", original_csv)
            new_zip.writestr("old_ArrDataHub.txt", arr_txt_bytes)

            # adjusted BomIfds.csv
            if rainfall_factors is None:
                print("WARNING: rainfall CCFs not found for the chosen SSP/year; BomIfds.csv will not be adjusted.")
                new_zip.writestr("BomIfds.csv", original_csv)
            else:
                updated_csv = apply_factors_to_csv(original_csv, rainfall_factors)
                new_zip.writestr("BomIfds.csv", updated_csv)

            # adjusted ArrDataHub.txt (losses)
            updated_arr_txt = apply_factors_to_losses(arr_txt, init_loss, cont_loss)
            new_zip.writestr("ArrDataHub.txt", updated_arr_txt.encode("utf-8"))

            # write adjustment info file
            adj_lines = [
                f"SSP: {ssp}",
                f"Design Year: {year}",
                f"Rainfall CCF count: {len(rainfall_factors) if rainfall_factors else 'N/A'}",
                f"Initial loss factor: {init_loss}",
                f"Continuing loss factor: {cont_loss}",
                f"Temperature change (°C): {temp_change}"
            ]
            new_zip.writestr("adjustment_info.txt", ("\n".join(adj_lines)).encode("utf-8"))

    os.replace(temp_zip, copy_path)
    print(f"✅ Updated ARR ZIP created: {copy_path}")

    # print updated storm loss lines for quick verification
    for line in updated_arr_txt.splitlines():
        if line.lower().startswith("storm initial losses") or line.lower().startswith("storm continuing losses"):
            print(line)

    # print temperature change again
    print(f"Temperature change for {ssp} / {year}: {temp_change} °C")

    # extract to folder with same base name
    extract_folder = copy_path[:-4]  # remove ".zip"
    os.makedirs(extract_folder, exist_ok=True)
    with zipfile.ZipFile(copy_path, "r") as zf:
        zf.extractall(extract_folder)
    print(f"📂 Extracted contents to: {extract_folder}")

if __name__ == "__main__":
    copy_and_update_zip()
