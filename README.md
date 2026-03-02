# Avaliação de IDS baseados em Aprendizado de Máquina — cenários realistas

Este repositório organiza a proposta de avaliação de Sistemas de Detecção de Intrusão baseados em Aprendizado de Máquina (IDS-AM) a partir de três dimensões que costumam ser tratadas de forma isolada em avaliações tradicionais: mudança de conceito, ataques não observados e mudança de ambiente.

A motivação central é aproximar a avaliação das condições observadas em ambientes reais, evitando superestimação de desempenho causada por conjuntos estáticos e pressupostos de estabilidade.

---

## Estrutura principal: 3 cenários

### 1) Mudança de conceito (concept drift)
Cenário em que as distribuições dos dados evoluem ao longo do tempo, afetando a estabilidade do desempenho do IDS. A avaliação pontual tende a não capturar degradações temporais, o que exige protocolos temporais estruturados e análises ao longo de janelas/tempo.

**Ideia-chave**
- Evolução temporal das distribuições dos dados e impacto no desempenho do IDS.
- Necessidade de avaliar o comportamento ao longo do tempo, em vez de um único “snapshot”.

---

### 2) Ataques não observados
Cenário em que aparecem ataques não vistos na fase de treinamento (novas classes ou variações), quebrando a suposição de “conjunto fechado” e pressionando a capacidade de generalização do modelo.

**Ideia-chave**
- Separar ataques observados vs. não observados e medir a degradação de generalização.
- Avaliar generalização entre classes e intra-classe (variações dentro de uma mesma família de ataque).
---

### 3) Mudança de ambiente
Cenário em que variações de infraestrutura e configuração alteram as características do tráfego coletado, limitando a transferibilidade direta de resultados entre contextos distintos.

**Ideia-chave**
- Resultados obtidos em um ambiente não são automaticamente replicáveis em outro.
- Diferenças de infraestrutura podem alterar a distribuição dos dados e o desempenho do IDS. :

---

## Estrutura de pastas

Cada cenário é um “projeto” independente dentro deste repositório, contendo seu próprio `README.md` e os códigos necessários para reprodução.

```text
.
├── README.md
├── mudanca-de-conceito/
│   ├── README.md
│   ├── scripts/
├── ataques-nao-observados/
│   ├── README.md
│   ├── scripts/
└── mudanca-de-ambiente/
    ├── README.md
    └── scripts/
```
