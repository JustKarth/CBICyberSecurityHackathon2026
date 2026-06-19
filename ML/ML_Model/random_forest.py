import pandas as pd
import numpy as np
import joblib

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.decomposition import PCA
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
from sklearn.metrics import roc_curve
import matplotlib.pyplot as plt

# Load first 100k rows

df = pd.read_csv(
    "train_transaction.csv",
    nrows=100000
)

print("Original Shape:", df.shape)

# Reduce memory usage

float_cols = df.select_dtypes(include=["float64"]).columns
df[float_cols] = df[float_cols].astype("float32")

int_cols = df.select_dtypes(include=["int64"]).columns
df[int_cols] = df[int_cols].astype("int32")

# Separate target

y = df["isFraud"]
X = df.drop(columns=["isFraud"])

# Remove highly missing columns

missing_ratio = X.isnull().mean()

drop_cols = missing_ratio[
    missing_ratio > 0.95
].index

X = X.drop(columns=drop_cols)

print("After Missing Value Removal:", X.shape)

# Remove constant columns

constant_cols = [
    col
    for col in X.columns
    if X[col].nunique(dropna=False) <= 1
]

X = X.drop(columns=constant_cols)

print("After Constant Feature Removal:", X.shape)

# Time features

if "TransactionDT" in X.columns:

    time_features = pd.DataFrame({
        "Day": X["TransactionDT"] // 86400,
        "Week": (X["TransactionDT"] // 86400) // 7,
        "Hour": (X["TransactionDT"] % 86400) // 3600
    })

    X = pd.concat(
        [X, time_features],
        axis=1
    )

# Encode categorical columns

cat_cols = X.select_dtypes(
    include=["object", "string", "category"]
).columns.tolist()

print(f"Encoding {len(cat_cols)} categorical columns")

for i, col in enumerate(cat_cols):

    print(f"Encoding {i+1}/{len(cat_cols)} : {col}")

    X[col] = (
        X[col]
        .fillna("Missing")
        .astype(str)
    )

    encoder = LabelEncoder()

    X[col] = encoder.fit_transform(
        X[col]
    )

print("Encoding complete")

# Lightweight missing value handling

print("Starting imputation")

for col in X.columns:

    if X[col].isnull().sum() > 0:

        X[col] = X[col].fillna(
            X[col].median()
        )

print("Imputation complete")

# Reduce memory again

for col in X.columns:

    if X[col].dtype == "float64":
        X[col] = X[col].astype("float32")

    elif X[col].dtype == "int64":
        X[col] = X[col].astype("int32")

print("After Imputation:", X.shape)

# PCA on V features

v_cols = [
    col
    for col in X.columns
    if col.startswith("V")
]

if len(v_cols) > 0:

    n_components = min(10, len(v_cols))

    print(
        f"Compressing {len(v_cols)} V features into {n_components} PCA components"
    )

    pca = PCA(
        n_components=n_components,
        random_state=42
    )

    v_pca = pca.fit_transform(
        X[v_cols]
    )

    pca_df = pd.DataFrame(
        v_pca,
        columns=[
            f"V_PCA_{i+1}"
            for i in range(n_components)
        ]
    )

    X = pd.concat(
        [
            X.drop(columns=v_cols).reset_index(drop=True),
            pca_df.reset_index(drop=True)
        ],
        axis=1
    )

print("After PCA:", X.shape)

# Train-test split

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    stratify=y,
    random_state=42
)

print("Train Shape:", X_train.shape)

# Initial RF

print("Training initial Random Forest")

rf = RandomForestClassifier(
    n_estimators=25,
    max_depth=8,
    n_jobs=2,
    random_state=42
)

rf.fit(
    X_train,
    y_train
)

print("Initial RF complete")

# Feature importance

importance = pd.Series(
    rf.feature_importances_,
    index=X_train.columns
).sort_values(
    ascending=False
)

TOP_N = 30

selected_features = (
    importance.head(TOP_N)
    .index
)

print("Top Features:")
print(selected_features.tolist())

# Reduce feature set

X_train_small = X_train[selected_features]
X_test_small = X_test[selected_features]

# Final RF

print("Training final Random Forest")

final_rf = RandomForestClassifier(
    n_estimators=50,
    max_depth=8,
    n_jobs=2,
    random_state=42
)

final_rf.fit(
    X_train_small,
    y_train
)

print("Final RF complete")

# Evaluation

preds = final_rf.predict_proba(
    X_test_small
)[:, 1]

auc = roc_auc_score(
    y_test,
    preds
)

print("\nFinal ROC-AUC:", round(auc, 4))

# ROC Curve

fpr, tpr, thresholds = roc_curve(
    y_test,
    preds
)

plt.figure(figsize=(8,6))

plt.plot(
    fpr,
    tpr,
    linewidth=2,
    label=f"Random Forest (AUC = {auc:.4f})"
)

# Random guessing baseline
plt.plot(
    [0, 1],
    [0, 1],
    linestyle="--",
    label="Random Classifier"
)

plt.xlabel("False Positive Rate")
plt.ylabel("True Positive Rate")
plt.title("ROC Curve")

plt.legend()
plt.grid(True)

plt.tight_layout()

plt.savefig(
    "roc_curve.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()

print("ROC curve saved as roc_curve.png")

# Save outputs

importance.to_csv(
    "feature_importance.csv"
)

joblib.dump(
    final_rf,
    "fraud_random_forest.pkl"
)

joblib.dump(
    list(selected_features),
    "selected_features.pkl"
)

print("Model Saved")