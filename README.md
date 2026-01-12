# Smartphone Placement Recognition for Real-World Gait Analysis

This repository provides the code, data structure, and trained models used for **smartphone placement recognition (SPR)** during walking, as presented in our work on real-world gait analysis.  
The goal is to automatically recognize the **body placement of a smartphone** using inertial data, enabling more reliable and scalable gait assessment in free-living conditions.

---

## 📌 Objective

Smartphone placement strongly influences gait-derived metrics (e.g., step count, stride length, variability).  
This project aims to:

- Automatically recognize smartphone placement during **level walking**
- Operate in **heterogeneous, real-world, unsupervised conditions**
- Support **robust gait analysis pipelines** by enabling placement-aware processing

The proposed framework is designed to generalize across:
- Subjects
- Environments (laboratory vs free-living)
- Smartphone hardware and operating systems

---

## 📱 Smartphone Placements

During acquisitions, **all smartphone locations recorded data simultaneously**.  
Six common placements were considered:

- **Hand-held (H)**: Held in the hand during natural arm swing  
- **Shoulder Bag (SB)**: Carried in a shoulder bag  
- **Front Pocket (FP)**: Front pocket of trousers or jeans  
- **Back Pocket (BP)**: Back pocket of trousers or jeans  
- **Coat Pocket (CP)**: Side pocket of a jacket or coat  
- **Lower-Back (LB)**: Belt-fixed at the level of the **5th lumbar vertebra (L5)**, landscape orientation  

These placements reflect frequent real-life usage and introduce increasing levels of motion variability, with bag-based placements being the most challenging.

---

## 🧭 Reference System: INDIP

Data collection relied on the **INDIP system (INertial module with DIstance sensors and Pressure insoles)** as reference system.

> Salis et al., 2023 – *Frontiers in Bioengineering and Biotechnology*  
> DOI: 10.3389/fbioe.2023.1143248

The INDIP system is a wearable multi-sensor platform for real-world gait analysis, extensively validated and adopted in multiple studies.

**Adopted configuration:**
- 3 magneto-IMUs (both feet + lower back)
- 2 pressure insoles

To facilitate synchronization:
- The **Lower-Back smartphone** and the **lower-back INDIP IMU** were **co-located at L5**

This configuration enables reliable gait-sequence detection and alignment between reference and smartphone signals.

---
### Sensor Orientation and Reference Frames

During data acquisition, **smartphones were carried by participants with no constraints on orientation**. This design choice reflects real-world usage conditions, where smartphone orientation can vary substantially across users and over time. Consequently, all features adopted in this work were designed to be **orientation-invariant**, relying on acceleration and angular velocity magnitudes.

In contrast, the **INDIP reference system sensors followed a standardized orientation convention**. The magneto-inertial measurement units (MIMUs) of the INDIP system were mounted according to the reference frames defined by the Mobilise-D consortium, ensuring consistency and reproducibility across subjects and studies. Sensor axes were aligned following the conventions described in:

> Palmerini, L., Reggi, L., Bonci, T. *et al.*  
> **Mobility recorded by wearable devices and gold standards: the Mobilise-D procedure for data standardization.**  
> *Scientific Data*, 10, 38 (2023).  
> https://doi.org/10.1038/s41597-023-01930-9

This distinction highlights the dual role of the INDIP system as a **gold-standard reference**, requiring strict control of sensor orientation, and smartphones as **unconstrained consumer devices**, whose placement and orientation variability must be addressed algorithmically.

---

## 📂 Repository Structure

```

smartphone-placement-recognition/
│
├── src/
│   ├── methods/
│   │   └── train_SPR.m              # Feature selection + model training
│   │
│   └── utils/
│       ├── computeModelSummary.m    # Metrics aggregation
│       ├── evaluateModelVisualization.m  # Confusion matrices & plots
│       └── reduceLabels.m           # Label reduction (6 → 5 → 4 classes)
│   │   └── train_SPR.m
│   │
│   └── utils/
│       ├── computeModelSummary.m
│       ├── evaluateModelVisualization.m
│       └── reduceLabels.m
│
├── scripts/
│   └── test_SPR.m                   # Testing on Custom Laboratory dataset
│
├── data/
│   ├── CustomLab.mat                # Laboratory walking features
│   └── CustomFreeLiving.mat         # Free-living walking features
│
├── results/
│   ├── models/
│   │   └── best_model_50_features/
│   │       ├── ConfusionMatrix.fig
│   │       ├── ensModel.mat         # Trained ensemble model
│   │       └── FeatSel_Results.mat  # Selected features
│   └── performance_FS.xlsx          # Performance summary
=======
│   ├── CustomLab.mat
│   └── CustomFreeLiving.mat
│
├── results/
│   ├── models/
│   |    ├── best_model_50_features/
│   |       ├── ConfusionMatrix.fig
│   |       ├── ensModel.mat
│   |       └── FeatSel_Results.mat
│   └── performance_FS.xlsx
│
├── .gitignore
├── LICENSE
└── README.md

```

---

## 📊 Data Format

Both `CustomLab.mat` and `CustomFreeLiving.mat` contain MATLAB tables with:

- **Rows**: 10-second walking windows
- **Columns**:
  - Orientation-invariant accelerometer and gyroscope magnitude features
  - Metadata:
    - `Position` (ground-truth smartphone placement)
    - `SubjectID`

Only **walking segments** are included.  
Stationary windows are excluded based on angular velocity thresholds.

---

## ⚙️ Training Pipeline

The training pipeline is implemented in `src/methods/train_SPR.m` and consists of:

### 1️⃣ Subject-Independent Split
- Subjects are randomly divided into:
  - **Construction Set (CS)**: used for feature selection and model tuning
  - **Test Set (TS)**: held-out subjects for evaluation
- This ensures **subject-independent validation**

---

### 2️⃣ Feature Selection

A **two-stage feature selection** strategy is adopted:

#### Stage 1 – MRMR Ranking
- Maximum Relevance Minimum Redundancy (MRMR)
- Applied **only on CS data**
- Produces a ranked list of features

#### Stage 2 – Wrapper Selection
- Progressive inclusion of features (e.g., 10 → 20 → ... → 50)
- Model performance evaluated for each subset
- Optimal subset selected based on accuracy on held-out CS subjects

---

### 3️⃣ Model and Hyperparameter Optimization

- Classifier: **Decision-tree ensemble (AdaBoostM2)**
- Training performed using MATLAB `fitcensemble`
- Hyperparameters optimized via **Bayesian Optimization**:
  - Number of learners
  - Learning rate
  - Maximum number of splits
- Optimization objective: **classification accuracy**
- Maximum of **50 optimization iterations**

This process balances performance and overfitting robustness.

---

### 4️⃣ Classification Tasks

The framework supports multiple granularity levels:

- **6-class**: All placements distinct  
- **5-class**: Front + Back Pocket merged  
- **4-class**: All pockets merged  

This allows analysis of how placement granularity affects recognition performance.

---

## 📈 Evaluation

Evaluation includes:

- Overall accuracy (micro)
- Per-class precision and recall
- Balanced accuracy
- Confusion matrices (row- and column-normalized)

Testing is performed:
- Internally (Custom datasets)
- Externally (public datasets, not included here)

---

## 📚 Publications

### Conference Paper (available)
> **G. Trentadue, P. Tasca, et al.**  
> *Automatic recognition of smartphone location with machine learning for real-world gait analysis*  
> **Gait & Posture**, Volume 122 (Supplement), 2025  
> DOI: 10.1016/j.gaitpost.2025.08.032  

### Journal Paper
A full journal extension is **currently under preparation** (coming soon).

---

## 📄 License

This project is released under the **MIT License**.  
See the `LICENSE` file for details.

---

## 📬 Contact

For questions, collaborations, or clarifications:

**Paolo Tasca**  
📧 paolo.tasca@polito.it  
Politecnico di Torino
```

---

Se vuoi, nel prossimo step posso:

* adattare il README per **reviewer-friendly wording**
* aggiungere una sezione **Reproducibility**
* controllare la **coerenza terminologica** con il journal paper (SPR vs SLR, placement vs location)
* suggerirti **badges GitHub** (license, MATLAB, DOI, ecc.)

Dimmi tu 👍
