"""
graficos.py

Conversão do script R (graficos.R) para Python.
- Lê os CSVs (separador ';')
- Calcula métricas por janela (precision/recall/F1) + médias de y e y_pred
- Plota séries temporais com Plotly

Requisitos:
    pip install pandas numpy scikit-learn plotly

Uso:
    python graficos.py --base-dir main_project --window 50
Opcional:
    python graficos.py --save-html out_dir
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Tuple

import numpy as np
import pandas as pd
from sklearn.metrics import precision_score, recall_score, f1_score
import plotly.graph_objects as go


@dataclass(frozen=True)
class WindowMetrics:
    id: int
    precisao: float
    revocacao: float
    f1: float
    obs_avg_y: float
    pred_avg_y: float


def _to_numeric_labels(series: pd.Series) -> np.ndarray:
    """
    No R, foi feito: as.factor(as.character(x)) e depois as.numeric(as.character(x)).
    Aqui, garantimos que os rótulos sejam strings e depois tentamos converter para int.
    """
    s = series.astype(str)
    # aceita "0"/"1" e também "0.0"/"1.0"
    return pd.to_numeric(s, errors="coerce").fillna(0).astype(int).to_numpy()


def compute_window_metrics(
    df: pd.DataFrame,
    window: int = 50,
    positive_label: int = 1,
    y_col: str = "y",
    y_pred_col: str = "y_pred",
) -> pd.DataFrame:
    """
    Replica a lógica do R:
        size <- trunc(nrow(df)/window)
        df_window <- df[((i-1)*size + 1):(i*size), ]
    Observação: o R ignora a "sobra" se nrow não for múltiplo de window.
    """
    if window <= 0:
        raise ValueError("window deve ser > 0")

    n = len(df)
    size = int(n // window)
    if size == 0:
        raise ValueError(f"dataset muito pequeno (n={n}) para window={window}")

    y_all = _to_numeric_labels(df[y_col])
    y_pred_all = _to_numeric_labels(df[y_pred_col])

    rows = []
    for i in range(1, window + 1):
        start = (i - 1) * size
        end = i * size  # exclusivo
        y = y_all[start:end]
        y_pred = y_pred_all[start:end]

        # Métricas binárias com definição explícita do rótulo positivo
        prec = precision_score(y, y_pred, pos_label=positive_label, zero_division=0)
        rec = recall_score(y, y_pred, pos_label=positive_label, zero_division=0)
        f1 = f1_score(y, y_pred, pos_label=positive_label, zero_division=0)

        obs_avg = float(np.mean(y)) if len(y) else 0.0
        pred_avg = float(np.mean(y_pred)) if len(y_pred) else 0.0

        rows.append(WindowMetrics(i, float(prec), float(rec), float(f1), obs_avg, pred_avg))

    return pd.DataFrame([r.__dict__ for r in rows])


def make_figure(df_metric: pd.DataFrame, title: str) -> go.Figure:
    fig = go.Figure()
    fig.add_trace(go.Scatter(x=df_metric["id"], y=df_metric["precisao"], mode="lines", name="precisao"))
    fig.add_trace(go.Scatter(x=df_metric["id"], y=df_metric["revocacao"], mode="lines", name="revocacao"))
    fig.add_trace(go.Scatter(x=df_metric["id"], y=df_metric["f1"], mode="lines", name="f1"))
    fig.add_trace(go.Scatter(x=df_metric["id"], y=df_metric["obs_avg_y"], mode="lines", name="obs_avg_y"))
    fig.add_trace(go.Scatter(x=df_metric["id"], y=df_metric["pred_avg_y"], mode="lines", name="pred_avg_y"))

    fig.update_layout(
        title=title,
        xaxis_title="id (janela)",
        yaxis_title="valor",
        legend_title_text="séries",
    )
    return fig


def read_csv_semicolon(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {path}")
    return pd.read_csv(path, sep=";")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-dir", type=str, default="main_project", help="Diretório onde estão os CSVs")
    parser.add_argument("--window", type=int, default=50, help="Número de janelas")
    parser.add_argument("--save-html", type=str, default=None, help="Diretório para salvar figuras em HTML (opcional)")
    args = parser.parse_args()

    base_dir = Path(args.base_dir)
    window = args.window

    # Arquivos conforme o R
    p_gradual = base_dir / "df_gradual_dos.csv"
    p_sudden = base_dir / "df_sudden_dos_predict.csv"
    p_rec = base_dir / "df_sudden_rec_dos.csv"

    df_gradual = read_csv_semicolon(p_gradual)
    df_sudden = read_csv_semicolon(p_sudden)
    df_rec = read_csv_semicolon(p_rec)

    # 1) Sudden: positive.class="1"
    m_sudden = compute_window_metrics(df_sudden, window=window, positive_label=1)
    fig_sudden = make_figure(m_sudden, title="Sudden drift — métricas por janela")

    # 2) Sudden recurring: positive.class="1"
    m_rec = compute_window_metrics(df_rec, window=window, positive_label=1)
    fig_rec = make_figure(m_rec, title="Sudden recurring drift — métricas por janela")

    # 3) Gradual: no R está positive.class="0"
    m_gradual = compute_window_metrics(df_gradual, window=window, positive_label=0)
    fig_gradual = make_figure(m_gradual, title="Gradual drift — métricas por janela")

    if args.save_html is not None:
        out = Path(args.save_html)
        out.mkdir(parents=True, exist_ok=True)
        fig_sudden.write_html(out / "sudden_metrics.html")
        fig_rec.write_html(out / "sudden_rec_metrics.html")
        fig_gradual.write_html(out / "gradual_metrics.html")
        print(f"Figuras salvas em: {out.resolve()}")

    # Mostra (abre no navegador/renderer configurado)
    fig_sudden.show()
    fig_rec.show()
    fig_gradual.show()


if __name__ == "__main__":
    main()
