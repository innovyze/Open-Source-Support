import os
import tkinter as tk
from tkinter import filedialog, ttk, messagebox
import pandas as pd
import io
import re

# ---------------- Utility helpers ----------------
def read_text_file(path):
    """Read text file with UTF-8 fallback to Latin-1."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except UnicodeDecodeError:
        with open(path, "r", encoding="latin-1") as f:
            return f.read()

def write_text_file(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)

# ---------------- UI ----------------
def get_user_choices():
    root = tk.Tk()
    root.title("Select Options")
    root.geometry("360x240")

    ssp_var = tk.StringVar()
    year_var = tk.StringVar()

    tk.Label(root, text="Select Shared Socioeconomic Pathway (SSP)").pack(pady=5)
    ssp_dropdown = ttk.Combobox(
        root,
        textvariable=ssp_var,
        values=["SSP1-2.6", "SSP2-4.5", "SSP3-7.0", "SSP5-8.5"],
        state="readonly",
        width=22
    )
    ssp_dropdown.pack(pady=5)

    tk.Label(root, text="Select Design Year").pack(pady=5)
    year_dropdown = ttk.Combobox(
        root,
        textvariable=year_var,
        values=["2030", "2040", "2050", "2060", "2070", "2080", "2090", "2100"],
        state="readonly",
        width=12
    )
    year_dropdown.pack(pady=5)

    def on_ssp_select(event):
        ssp_var.set(ssp_dropdown.get())

    def on_year_select(event):
        year_var.set(year_dropdown.get())

    ssp_dropdown.bind("<<ComboboxSelected>>", on_ssp_select)
    year_dropdown.bind("<<ComboboxSelected>>", on_year_select)

    def submit():
        ssp_choice = ssp_var.get()
        year_choice = year_var.get()
        if not ssp_choice or not year_choice:
            messagebox.showerror("Selection Error", "Please select both SSP and Design Year.")
            return
        root.quit()

    tk.Button(root, text="Submit", command=submit).pack(pady=15)
    root.mainloop()

    ssp = ssp_var.get()
    year = year_var.get()
    root.destroy()
    return ssp, year

# ---------------- Parsers ----------------
def parse_section_table(txt_content, section_name, ssp, year):
    """Parse a section with SSP columns and year rows."""
    lines = txt_content.splitlines()
    inside = False
    header = None
    idx = None
    for line in lines:
        if re.match(rf"^\s*\[{re.escape(section_name)}\]\s*$", line, flags=re.I):
            inside = True
            continue
        if inside:
            if re.match(r"^\s*\[END_", line, flags=re.I):
                break
            if header is None:
                header = [h.strip() for h in line.split(",")]
                for j, h in enumerate(header):
                    if ssp.lower() in h.lower():
                        idx = j
                        break
                continue
            parts = [p.strip() for p in line.split(",")]
            if parts and parts[0] == str(year):
                if idx is not None and idx < len(parts):
                    m = re.search(r"[-+]?\d*\.\d+|\d+", parts[idx])
                    if m:
                        return float(m.group())
    return None

def parse_rainfall_ccf(txt_content, ssp, year):
    """Return rainfall change factors from the chosen SSP section."""
    lines = txt_content.splitlines()
    inside = False
    for line in lines:
        if re.match(rf"^\s*\[{re.escape(ssp)}\]\s*$", line, flags=re.I):
            inside = True
            continue
        if inside:
            if re.match(r"^\s*\[END_", line, flags=re.I):
                break
            parts = [p.strip() for p in line.split(",")]
            if parts and parts[0] == str(year):
                vals = []
                for tok in parts[1:]:
                    m = re.search(r"[-+]?\d*\.\d+|\d+", tok)
                    if m:
                        vals.append(float(m.group()))
                return vals[:10] if vals else None
    return None

# ---------------- Apply rainfall factors ----------------
def apply_factors_to_csv(csv_path, factors, output_path):
    """Multiply rainfall depths in the CSV by the corresponding duration factors."""
    with open(csv_path, "r", encoding="utf-8") as f:
        text = f.read()
    lines = text.splitlines()

    header_index = next(i for i, l in enumerate(lines) if re.match(r"^\s*Duration\s*,\s*Duration\s*in\s*min", l, re.I))
    header_lines = lines[:header_index]
    data_lines = lines[header_index:]
    df = pd.read_csv(io.StringIO("\n".join(data_lines)))

    duration_map = {1.0:0,1.5:1,2.0:2,3.0:3,4.5:4,6.0:5,9.0:6,12.0:7,18.0:8,24.0:9}
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
            factor = f_lower + (f_upper - f_lower) * ((dur_hr - lower)/(upper - lower))
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
    df.to_csv(out, index=False, lineterminator="\n")  # ✅ correct argument
    write_text_file(output_path, out.getvalue())

# ---------------- Apply loss factors ----------------
def apply_factors_to_losses(txt_path, init_factor, cont_factor, output_path):
    """Update [LOSSES] values in ArrDataHub.txt."""
    txt = read_text_file(txt_path)
    lines = txt.splitlines()
    new_lines = []
    inside = False
    for line in lines:
        stripped = line.strip()
        if re.match(r"^\s*\[LOSSES\]\s*$", stripped, flags=re.I):
            inside = True
            new_lines.append(line)
            continue
        if inside and re.match(r"^\s*\[.*\]\s*$", stripped) and not re.match(r"^\s*\[LOSSES\]\s*$", stripped, flags=re.I):
            inside = False
            new_lines.append(line)
            continue
        if inside:
            if stripped.lower().startswith("storm initial losses") and init_factor:
                m = re.search(r"([-+]?\d*\.\d+|\d+)", line)
                if m:
                    orig = float(m.group())
                    newv = round(orig * init_factor, 2)
                    print(f"Updating Storm Initial Losses: {orig} × {init_factor} = {newv}")
                    line = line[:m.start()] + str(newv) + line[m.end():]
            if stripped.lower().startswith("storm continuing losses") and cont_factor:
                m = re.search(r"([-+]?\d*\.\d+|\d+)", line)
                if m:
                    orig = float(m.group())
                    newv = round(orig * cont_factor, 2)
                    print(f"Updating Storm Continuing Losses: {orig} × {cont_factor} = {newv}")
                    line = line[:m.start()] + str(newv) + line[m.end():]
        new_lines.append(line)
    write_text_file(output_path, "\n".join(new_lines))

# ---------------- Main ----------------
def main():
    root = tk.Tk()
    root.withdraw()

    txt_path = filedialog.askopenfilename(title="Select ArrDataHub text file", filetypes=[("Text files","*.txt"),("All files","*.*")])
    if not txt_path:
        print("No text file selected.")
        return
    csv_path = filedialog.askopenfilename(title="Select BomIfds CSV file", filetypes=[("CSV files","*.csv"),("All files","*.*")])
    if not csv_path:
        print("No CSV file selected.")
        return

    ssp, year = get_user_choices()
    arr_txt = read_text_file(txt_path)

    rainfall_factors = parse_rainfall_ccf(arr_txt, ssp, year)
    init_loss = parse_section_table(arr_txt, "Climate_Change_INITIAL_LOSS", ssp, year)
    cont_loss = parse_section_table(arr_txt, "Climate_Change_CONTINUING_LOSS", ssp, year)
    temp_change = parse_section_table(arr_txt, "TEMPERATURE_CHANGES", ssp, year)

    print(f"\nParsed values for SSP={ssp}, Year={year}")
    print("Rainfall factors:", rainfall_factors)
    print("Initial Loss Factor:", init_loss)
    print("Continuing Loss Factor:", cont_loss)
    print("Temperature Change:", temp_change)

    if rainfall_factors is None:
        messagebox.showerror("Error", f"Could not find rainfall factors for {ssp} {year}.")
        return

    folder = os.path.dirname(txt_path)
    txt_name = os.path.splitext(os.path.basename(txt_path))[0]
    csv_name = os.path.splitext(os.path.basename(csv_path))[0]

    # ✅ Include temperature change in filename (rounded to 1 decimal)
    temp_suffix = f"_T{round(temp_change,1)}" if temp_change is not None else ""
    updated_txt = os.path.join(folder, f"{txt_name}_{ssp}_{year}{temp_suffix}.txt")
    updated_csv = os.path.join(folder, f"{csv_name}_{ssp}_{year}{temp_suffix}.csv")

    apply_factors_to_csv(csv_path, rainfall_factors, updated_csv)
    apply_factors_to_losses(txt_path, init_loss, cont_loss, updated_txt)

    print(f"\n✅ Updated files written:\n - {updated_txt}\n - {updated_csv}")
    messagebox.showinfo("Done", f"Updated files created:\n\n{updated_txt}\n{updated_csv}")

if __name__ == "__main__":
    main()
