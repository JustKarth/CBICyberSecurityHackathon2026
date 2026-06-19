import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

train_transaction = pd.read_csv("train_transaction.csv")

fraud_df = train_transaction[
    train_transaction['isFraud'] == 1
]

numeric_cols = fraud_df.select_dtypes(
    include=['int64','float64']
)

# Top 30 most variable features among frauds
top_features = (
    numeric_cols.var()
    .sort_values(ascending=False)
    .head(30)
    .index
)

corr_matrix = fraud_df[top_features].corr()

plt.figure(figsize=(16,12))

sns.heatmap(
    corr_matrix,
    cmap='coolwarm',
    center=0,
    square=True
)

plt.title(
    'Top 30 Feature Correlations Within Fraud Transactions'
)

plt.tight_layout()

plt.savefig(
    'fraud_top30_heatmap.png',
    dpi=300,
    bbox_inches='tight'
)

plt.close()
