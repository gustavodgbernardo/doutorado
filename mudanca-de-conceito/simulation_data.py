"""
Script de geração de bases simuladas para mudança de conceito (drift).

Conversão de simulation_data.R para Python.

Requisitos:
- pandas
- numpy
- (opcional) plotly, caso queira reproduzir os gráficos

Uso típico:
    python simulation_data.py --input /caminho/CIC2017-nfstream-target.csv --sep ';' --outdir data
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from simulation_functions import sudden_drift, gradual_drift


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=str, required=True, help="CSV de entrada (ex.: CIC2017-nfstream-target.csv)")
    ap.add_argument("--sep", type=str, default=";", help="Separador do CSV (default=';')")
    ap.add_argument("--target", type=str, default="label", help="Nome da coluna alvo (default='label')")
    ap.add_argument("--outdir", type=str, default="data", help="Diretório de saída (default='data')")
    ap.add_argument("--seed", type=int, default=42, help="Seed para reprodutibilidade (default=42)")
    return ap.parse_args()


def main() -> None:
    args = parse_args()
    rng = np.random.default_rng(args.seed)

    df = pd.read_csv(args.input, sep=args.sep)

    target = args.target
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    # benignos (primeiros 50000)
    df_benign = df.loc[df[target] == "benign"].head(50000).copy()

    # ataques
    df_attack_dos = df.loc[df[target] == "DoS-Hulk"].copy()
    df_attack_ftp = df.loc[df[target] == "FTP-Patator"].copy()
    df_attack_web = df.loc[df[target] == "Web-Attack-Brute-Force"].copy()

    # abrupto
    df_sudden_dos = sudden_drift(df_benign, df_attack_dos, recurrence_period=1, rng=rng)
    df_sudden_ftp = sudden_drift(df_benign, df_attack_ftp, recurrence_period=1, rng=rng)
    df_sudden_web = sudden_drift(df_benign, df_attack_web, recurrence_period=1, rng=rng)

    # abrupto recorrente
    df_sudden_rec_dos = sudden_drift(df_benign, df_attack_dos, recurrence_period=4, rng=rng)
    df_sudden_rec_ftp = sudden_drift(df_benign, df_attack_ftp, recurrence_period=3, rng=rng)
    df_sudden_rec_web = sudden_drift(df_benign, df_attack_web, recurrence_period=2, rng=rng)

    # gradual
    df_gradual_dos = gradual_drift(df_benign, df_attack_dos, rng=rng)
    df_gradual_ftp = gradual_drift(df_benign, df_attack_ftp, rng=rng)
    df_gradual_web = gradual_drift(df_benign, df_attack_web, rng=rng)

    # salvar arquivos (com todas as colunas)
    df_sudden_dos.to_csv(outdir / "df_sudden_dos_all.csv", sep=";", index=False)
    df_sudden_ftp.to_csv(outdir / "df_sudden_ftp_all.csv", sep=";", index=False)
    df_sudden_web.to_csv(outdir / "df_sudden_web_all.csv", sep=";", index=False)
    df_sudden_rec_dos.to_csv(outdir / "df_sudden_rec_dos_all.csv", sep=";", index=False)
    df_sudden_rec_ftp.to_csv(outdir / "df_sudden_rec_ftp_all.csv", sep=";", index=False)
    df_sudden_rec_web.to_csv(outdir / "df_sudden_rec_web_all.csv", sep=";", index=False)
    df_gradual_dos.to_csv(outdir / "df_gradual_dos_all.csv", sep=";", index=False)
    df_gradual_ftp.to_csv(outdir / "df_gradual_ftp_all.csv", sep=";", index=False)
    df_gradual_web.to_csv(outdir / "df_gradual_web_all.csv", sep=";", index=False)

    # remover variáveis: R usou c(15:77, 87) (1-based)
    # => python (0-based): 14:77 e 86
    def subset_cols(df_in: pd.DataFrame) -> pd.DataFrame:
        ncols = df_in.shape[1]
        idx = list(range(14, min(77, ncols)))  # 14..76
        if ncols > 86:
            idx.append(86)
        return df_in.iloc[:, idx]

    subset_cols(df_sudden_dos).to_csv(outdir / "df_sudden_dos.csv", sep=";", index=False)
    subset_cols(df_sudden_ftp).to_csv(outdir / "df_sudden_ftp.csv", sep=";", index=False)
    subset_cols(df_sudden_web).to_csv(outdir / "df_sudden_web.csv", sep=";", index=False)
    subset_cols(df_sudden_rec_dos).to_csv(outdir / "df_sudden_rec_dos.csv", sep=";", index=False)
    subset_cols(df_sudden_rec_ftp).to_csv(outdir / "df_sudden_rec_ftp.csv", sep=";", index=False)
    subset_cols(df_sudden_rec_web).to_csv(outdir / "df_sudden_rec_web.csv", sep=";", index=False)
    subset_cols(df_gradual_dos).to_csv(outdir / "df_gradual_dos.csv", sep=";", index=False)
    subset_cols(df_gradual_ftp).to_csv(outdir / "df_gradual_ftp.csv", sep=";", index=False)
    subset_cols(df_gradual_web).to_csv(outdir / "df_gradual_web.csv", sep=";", index=False)


if __name__ == "__main__":
    main()
