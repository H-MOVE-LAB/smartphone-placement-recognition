---

````markdown
# Smartphone Placement Recognition (SPR)

This repository provides the code, trained model, and example datasets used in our work on **smartphone placement recognition (SPR)** based on inertial sensing and machine learning.  
The goal is to automatically recognize the **physical placement of a smartphone on the body** (e.g., trouser pocket, bag, hand, etc.) using features extracted from inertial signals.

The repository is designed to support:
- **Reproducibility** of the training and evaluation pipeline  
- **Transparency** of feature selection and hyperparameter tuning  
- **Reusability** of the framework on external datasets  

---

## 📌 Objective

Smartphone placement recognition is a fundamental step for reliable activity recognition and digital health applications, as sensor signals strongly depend on device placement.

The objectives of this project are:
- To develop a **robust SPR framework** based on handcrafted features
- To evaluate generalization across subjects and datasets
- To provide a **trained reference model** and example data for external validation

---

## 📁 Repository Structure

```text
smartphone-placement-recognition/
│
├── src/
│   ├── methods/
│   │   └── train_SPR/
│   │       ├── main_train_ensemble.m
│   │       └── feature_selection_and_training.m
│   │
│   └── utils/
│       ├── evaluateModelSummary.m
│       ├── evaluateModelDetailed.m
│       ├── reduceLabels.m
│       ├── computeMetrics.m
│       └── other helper functions
│
├── scripts/
│   └── test_SPR.m
│
├── data/
│   ├── CustomLab.mat
│   ├── CustomFreeLiving.mat
│   └── README.md
│
├── results/
│   ├── best_model_50_features/
│   │   ├── trainedModel.mat
│   │   ├── selected_features.mat
│   │   └── training_info.txt
│   └── README.md
│
├── .gitignore
├── LICENSE
└── README.md
````

---

## 📊 Dataset Description

### Feature Tables (`.mat` files)

Each dataset is stored as a MATLAB table, where:

* **Rows** correspond to fixed-length signal windows
* **Columns** correspond to extracted features and metadata

### Feature composition

Features are extracted from accelerometer and gyroscope signals and include:

* Time-domain statistics (mean, variance, RMS, etc.)
* Frequency-domain descriptors
* Signal magnitude features
* Correlation-based features (removed in some experiments)

### Metadata columns

The last columns of each table include:

* `Position` → ground-truth smartphone placement label
* `SubjectID` → anonymized subject identifier
* (Optional) session or test identifiers

Example:

```matlab
features = data{:, 1:end-2};
labels   = data.Position;
subjects = data.SubjectID;
```

---

## 🧠 Training Pipeline

The training procedure is implemented in:

```
src/methods/train_SPR/
```

### 1. Data Cleaning

* Removal of windows with low motion intensity
  (e.g., `MeanGyr < threshold`)
* Subject-wise split into:

  * **Construction Set (CS)**
  * **Test Set (TS)**

This prevents subject leakage between training and testing.

---

### 2. Feature Selection (MRMR)

Feature selection is performed using **Minimum Redundancy Maximum Relevance (MRMR)**:

```matlab
[idx, scores] = fscmrmr(Xtrain, Ytrain);
```

Experiments are conducted by progressively increasing the number of selected features
(e.g., 10, 20, …, 150).

The final released model uses the **top 50 features**, which provided the best trade-off between performance and model complexity.

---

### 3. Model Architecture

The SPR framework relies on ensemble classifiers (e.g., Random Forest, AdaBoost, or ECOC-SVM depending on configuration).

---

### 4. Hyperparameter Tuning

Hyperparameters are optimized using **Bayesian Optimization** (`bayesopt`) in MATLAB.

Optimized parameters include:

* Number of learning cycles
* Learning rate
* Maximum number of tree splits

The objective function is the cross-validated classification loss on the Construction Set.

Example:

```matlab
rfModel = fitcensemble( ...
    Xtrain, Ytrain, ...
    'Method', 'AdaBoostM2', ...
    'OptimizeHyperparameters', ...
    {'NumLearningCycles','LearnRate','MaxNumSplits'}, ...
    'HyperparameterOptimizationOptions', struct( ...
        'Optimizer','bayesopt', ...
        'MaxObjectiveEvaluations',50));
```

Only the **final optimized model** is stored in this repository.

---

## 📈 Evaluation

Model performance is evaluated using:

* Global (micro) accuracy
* Macro-averaged precision and recall
* Per-class:

  * Precision
  * Recall
  * Balanced accuracy

Two evaluation functions are provided:

* `evaluateModelSummary.m` → concise reporting
* `evaluateModelDetailed.m` → full metric vector for logging and statistical analysis

Evaluations are also performed on:

* Reduced **5-class**
* Reduced **4-class** problem formulations

---

## 🧪 External Validation

The script:

```text
scripts/test_SPR.m
```

allows testing the trained SPR model on:

* Custom laboratory datasets
* Free-living datasets

This enables evaluation of **cross-dataset generalization**.

---

## 📦 Released Results

To limit repository size, only:

* Example datasets
* The **best-performing trained model (50 features)**

are included.

Intermediate models and exploratory results are intentionally excluded.

---

## 📚 Related Publications

If you use this code, please cite:

> **[Authors]**
> *Smartphone Placement Recognition Using Inertial Sensing and Ensemble Learning*
> *Journal / Conference*, Year

(The reference will be updated upon publication.)

---

## 📜 License

This project is released under the **MIT License**.
You are free to use, modify, and distribute the code, provided proper credit is given.

---

## 📬 Contact

For questions, issues, or collaborations, please open an issue or contact the authors.

```

---

Se vuoi, nel prossimo passo posso:
- scrivere i **README separati per `data/` e `results/`**
- adattare il testo **per i reviewer di *Gait & Posture***
- aggiungere una sezione **“Reproducibility checklist”** (molto apprezzata dai journal)

Dimmi tu 👍
```
