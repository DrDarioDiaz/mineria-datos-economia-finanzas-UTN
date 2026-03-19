# Aplicaciones de Minería de Datos a Economía y Finanzas

**Maestría en Minería de Datos — UTN Facultad Regional Rosario | 2026**

[![Licencia MIT](https://img.shields.io/badge/Licencia-MIT-green.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![R](https://img.shields.io/badge/R-4.x-blue.svg)](https://www.r-project.org/)
[![Google Colab](https://img.shields.io/badge/Google-Colab-orange.svg)](https://colab.research.google.com/)

---

## 📌 Descripción del curso

Este repositorio contiene los materiales de trabajo del curso **Aplicaciones de Minería de Datos a Economía y Finanzas**, dictado en el marco de la Maestría en Minería de Datos de la UTN Facultad Regional Rosario (2026).

El curso aborda el proceso completo de descubrimiento de conocimiento en bases de datos económico-financieras: desde los marcos metodológicos estándar de la industria (CRISP-DM, SEMMA, Six Sigma) hasta la construcción, evaluación e interpretación de modelos predictivos avanzados, con énfasis en aplicaciones reales de scoring crediticio, detección de fraude y análisis de churn.

---

## 👨‍🏫 Docente

**Dr. Darío Ezequiel Díaz**

Doctor en Ciencias Económicas con Mención en Economía (UNC, 2014, Sobresaliente).
Posdoctorando en Inteligencia Artificial y sus Aplicaciones a las Ciencias Sociales (UNC, 2025–2026).
Doctorando en Estadística (UNR, 2024-2028), con Proyecto de tesis doctoral aprobado.
Magíster en Explotación de Datos y Gestión del Conocimiento (Austral, 2025).
Magíster en Métodos Cuantitativos para la Gestión y Análisis de Datos en Organizaciones (UBA, 2026).
Magíster en Políticas Públicas y Desarrollo (FLACSO, 2026).
Maestrando en Econometría (UTDT, 2024-2026) y en Políticas Económicas, Sociales y Regionales (UNC, 2024-2026) (Tesis en elaboración)
Director de Metodología y Relevamiento Estadístico — IPEC Misiones (desde 2016).

📧 drdarioezequieldiaz@gmail.com
🔗 [GitHub](https://github.com/DrDarioDiaz)

---

## 🗂️ Estructura del repositorio
```
mineria-datos-economia-finanzas-UTN/
│
├── 📁 colabs/              # Notebooks de Google Colab por unidad
│   ├── unidad_1_marcos_metodologicos.ipynb
│   ├── unidad_2_preparacion_datos.ipynb
│   ├── unidad_3_modelos_clasificacion.ipynb
│   ├── unidad_4_desbalanceo_sobreajuste.ipynb
│   ├── unidad_5_evaluacion_modelos.ipynb
│   └── unidad_6_proyecto_integrador.ipynb
│
├── 📁 datasets/            # Datasets utilizados en el curso
│   └── WA_Fn-UseC_-Telco-Customer-Churn.csv
│
├── 📁 presentaciones/      # Filminas de cada clase (PDF/PPTX)
│   ├── clase_01_marcos_metodologicos.pdf
│   ├── clase_02_database_marketing.pdf
│   └── ...
│
├── LICENSE
└── README.md
```

---

## 📚 Programa del curso — 6 Unidades

| Unidad | Tema | Clases | Fechas |
|--------|------|--------|--------|
| U1 | Marcos Metodológicos y Fundamentos | 1–2 | 26/03 · 09/04 |
| U2 | Preparación y Exploración de Datos | 3–4 | 16/04 · 23/04 |
| U3 | Modelos de Clasificación Aplicados a Finanzas | 5–7 | 30/04 · 07/05 · 14/05 |
| U4 | Datasets Desbalanceados y Sobreajuste | 8–9 | 21/05 · 28/05 |
| U5 | Evaluación y Comparación de Modelos | 10 | 04/06 |
| U6 | Proyecto Integrador: Análisis de Churn | 11–12 | 11/06 · 18/06 |

📅 **Frecuencia:** Jueves de 18:00 a 22:00 hs (hora de Buenos Aires) · Modalidad virtual vía Zoom

---

## 🛠️ Tecnologías y herramientas

| Herramienta | Uso |
|-------------|-----|
| **Python 3.10+** | Implementación principal de algoritmos y pipelines |
| **R 4.x** | Análisis estadístico y visualización complementaria |
| **Google Colab** | Entorno colaborativo sin instalación local |
| **scikit-learn** | Modelos de clasificación, preprocesamiento y evaluación |
| **imbalanced-learn** | SMOTE, ADASYN y técnicas de remuestreo |
| **XGBoost** | Gradient boosting de alta performance |
| **SHAP** | Interpretabilidad de modelos |
| **pandas / numpy** | Manipulación y análisis de datos |
| **matplotlib / seaborn** | Visualización de datos |

---

## 📊 Proyecto integrador — Análisis de Churn

El proyecto final del curso aplica la metodología **CRISP-DM** de forma integral sobre el dataset **Telco Customer Churn** (Kaggle/IBM), construyendo un pipeline completo en Python que abarca:

- Análisis exploratorio (EDA) con visualizaciones informativas
- Preprocesamiento: imputación, codificación y feature engineering
- Tratamiento del desbalanceo de clases (SMOTE, class_weight)
- Comparación de al menos 3 algoritmos de clasificación
- Evaluación con métricas financieras: AUC-ROC, Gini, KS
- Interpretabilidad con SHAP values
- Informe ejecutivo gerencial con recomendaciones accionables

🗃️ Dataset: [Telco Customer Churn — Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)

---

## ⚙️ Cómo usar los notebooks

1. Abrí cualquier notebook de la carpeta `colabs/` en Google Colab
2. Hacé clic en **"Abrir en Colab"** o usá el botón de abajo
3. Ejecutá las celdas en orden (Shift + Enter)
4. Los datasets necesarios están disponibles en la carpeta `datasets/`

[![Abrir en Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/)

---

## 📋 Sistema de evaluación

| Componente | Modalidad | Ponderación | Nota mínima |
|------------|-----------|-------------|-------------|
| Parcial teórico-conceptual | Individual | 40% | 7/10 |
| Informe ejecutivo | Grupal (hasta 3) | 35% | 7/10 |
| Defensa oral del proyecto | Grupal | 25% | 7/10 |

**Requisitos:** Asistencia ≥ 80% · Aprobación de los tres componentes

---

## 📄 Licencia

Este repositorio se distribuye bajo la licencia **MIT**. Los materiales pueden ser utilizados y adaptados libremente con atribución al autor original.

---

*Última actualización: marzo 2026*
