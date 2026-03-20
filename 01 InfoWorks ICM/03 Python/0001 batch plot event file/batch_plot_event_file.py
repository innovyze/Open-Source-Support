import pandas as pd
import matplotlib.pyplot as plt
import os

def read_csv(f):
    df = pd.read_csv(f)
    df.index = df['P_DATETIME']
    del df['P_DATETIME']
    return df

def plot(df, fld, figsize=(8,4)):
    fig, ax = plt.subplots(figsize=figsize)
    df.loc[:, [fld]].plot(ax=ax)
    return fig, ax

def batch_plot(csv_path, fig_folder):
    df = read_csv(csv_path)
    for fld in df.columns:
        fig, ax = plot(df, fld)
        ax.set_title(fld)
        fig.tight_layout()
        fig.savefig(os.path.join(fig_folder, '{}.png'.format(fld)))

csv_path = './../data/event_generic.csv'
fig_folder = './../data/fig'
batch_plot(csv_path, fig_folder)


df = read_csv(csv_path)
fig, ax = plot(df, df.columns[0])
