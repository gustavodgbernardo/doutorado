"""
Funções de simulação de mudança de conceito (drift).

Conversão direta de simulation_functions.R para Python.

Dependências:
- numpy
- pandas
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, List, Optional

import numpy as np
import pandas as pd


def break_n_array(n: int, p: int, rng: Optional[np.random.Generator] = None) -> List[int]:
    """
    Gera uma lista ordenada de pontos de corte (tamanhos acumulados) até n.

    Equivalente à função break_n_array do R:
      - se p == 1: retorna n
      - caso contrário: sorteia (p-1) valores em [1, n-1], arredonda/inteiriza, anexa n e ordena.

    Observação: no R, runif(min=0,max=n-1) com round pode gerar 0.
    Aqui é usado [1, n-1] para evitar cortes vazios/índices inválidos em slicing.
    """
    if rng is None:
        rng = np.random.default_rng()

    if p <= 1:
        return [int(n)]

    if n <= 1:
        return [int(n)]

    # valores inteiros entre 1 e n-1 (inclusive)
    cuts = rng.integers(1, n, size=p - 1).astype(int).tolist()
    cuts.append(int(n))
    cuts.sort()
    return cuts


def logit_function(x: np.ndarray | float) -> np.ndarray | float:
    """Equivalente ao logit_function do R: 1 / (1 + exp(-x))."""
    return 1.0 / (1.0 + np.exp(-x))


def sudden_drift(
    df_benign: pd.DataFrame,
    df_attack: pd.DataFrame,
    recurrence_period: int = 1,
    rng: Optional[np.random.Generator] = None,
) -> pd.DataFrame:
    """
    Drift abrupto/recorrente.

    Reproduz a lógica do R:
    - quebra benigno e ataque em `recurrence_period` blocos (via break_n_array)
    - intercala blocos benigno + ataque em ordem, concatenando no tempo.
    """
    if rng is None:
        rng = np.random.default_rng()

    b_breaks = break_n_array(len(df_benign), recurrence_period, rng=rng)
    a_breaks = break_n_array(len(df_attack), recurrence_period, rng=rng)

    parts = []
    prev_b = 0
    prev_a = 0
    for curr_b, curr_a in zip(b_breaks, a_breaks):
        # em R: (prev+1):curr (1-based, inclusive)
        # em pandas: [prev:curr) (0-based, end exclusive)
        parts.append(df_benign.iloc[prev_b:curr_b])
        parts.append(df_attack.iloc[prev_a:curr_a])
        prev_b, prev_a = curr_b, curr_a

    return pd.concat(parts, axis=0, ignore_index=True)


def gradual_drift(
    df_benign: pd.DataFrame,
    df_attack: pd.DataFrame,
    n_bgn_start: int = 10,
    f_prob: Callable[[np.ndarray], np.ndarray] = logit_function,
    rng: Optional[np.random.Generator] = None,
) -> pd.DataFrame:
    """
    Drift gradual.

    Conversão direta do R, preservando as escolhas de índices e a condição do loop.
    """
    if rng is None:
        rng = np.random.default_rng()

    n_attack = len(df_attack)
    n_benign = len(df_benign)

    if n_attack == 0:
        return df_benign.iloc[:n_bgn_start].copy()

    # i_attack e i_benign no R começam em 1 (1-based).
    i_attack = 1
    i_benign = 1
    i = 1

    x_int = np.arange(1, 3 * n_attack + 1)

    # R: scale(x_int, scale=sd(x_int)/4)
    # Aqui: (x - mean) / (sd/4)
    sd = np.std(x_int, ddof=1)
    scaled = (x_int - np.mean(x_int)) / (sd / 4.0) if sd > 0 else (x_int - np.mean(x_int))
    prob_attack = f_prob(scaled)

    df_gradual = df_benign.iloc[:n_bgn_start].copy()

    # R: while(i_attack != n_attack)
    # Observação: isso termina quando i_attack == n_attack e pode não incluir a última linha de ataque.
    while i_attack != n_attack:
        p = float(prob_attack[i - 1]) if (i - 1) < len(prob_attack) else float(prob_attack[-1])

        rand_attack = rng.binomial(1, p)
        i += 1

        if rand_attack == 0:
            # R: df_benign[i_benign+2, ] (1-based)
            # => pandas iloc: (i_benign+2)-1 = i_benign+1 (0-based)
            idx = i_benign + 1
            if idx >= n_benign:
                # se benigno acabar, força uso de ataque
                rand_attack = 1
            else:
                df_gradual = pd.concat([df_gradual, df_benign.iloc[[idx]]], axis=0, ignore_index=True)
                i_benign += 1

        if rand_attack == 1:
            # R: df_attact[i_attack, ] (1-based) => iloc[i_attack-1]
            idx = i_attack - 1
            if idx >= n_attack:
                break
            df_gradual = pd.concat([df_gradual, df_attack.iloc[[idx]]], axis=0, ignore_index=True)
            i_attack += 1

    return df_gradual
