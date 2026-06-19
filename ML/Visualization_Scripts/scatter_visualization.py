import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Load dataset
train_transaction = pd.read_csv("train_transaction.csv")

# Keep only required columns
ts_df = train_transaction[
    ['TransactionDT', 'TransactionAmt', 'isFraud']
].copy()

# Sort by transaction time
ts_df = ts_df.sort_values('TransactionDT')

# Convert seconds to days for x-axis
ts_df['Day'] = ts_df['TransactionDT'] / 86400

# Log transform amount
ts_df['LogAmt'] = np.log1p(ts_df['TransactionAmt'])

# Rolling statistics
WINDOW = 5000

ts_df['RollingMean'] = (
    ts_df['LogAmt']
    .rolling(window=WINDOW, min_periods=1)
    .mean()
)

ts_df['RollingMedian'] = (
    ts_df['LogAmt']
    .rolling(window=WINDOW, min_periods=1)
    .median()
)

# Sample transactions for scatter plot
sample = ts_df.sample(
    n=min(50000, len(ts_df)),
    random_state=42
)

fraud = sample[sample['isFraud'] == 1]
nonfraud = sample[sample['isFraud'] == 0]

# Plot
plt.figure(figsize=(20, 10))

# Non-fraud scatter
plt.scatter(
    nonfraud['Day'],
    nonfraud['LogAmt'],
    s=2,
    alpha=0.08,
    label='Non Fraud'
)

# Fraud scatter
plt.scatter(
    fraud['Day'],
    fraud['LogAmt'],
    s=10,
    alpha=0.7,
    label='Fraud'
)

# Rolling mean
plt.plot(
    ts_df['Day'],
    ts_df['RollingMean'],
    linewidth=3,
    label=f'Rolling Mean ({WINDOW} txns)'
)

# Rolling median
plt.plot(
    ts_df['Day'],
    ts_df['RollingMedian'],
    linewidth=3,
    linestyle='--',
    label=f'Rolling Median ({WINDOW} txns)'
)

plt.xlabel("Day", fontsize=13)
plt.ylabel("log(1 + TransactionAmt)", fontsize=13)
plt.title(
    "IEEE-CIS Transaction Amount Time Series",
    fontsize=18
)

plt.grid(alpha=0.3)
plt.legend(fontsize=11)

plt.tight_layout()

plt.savefig(
    "continuous_transaction_trend.png",
    dpi=300,
    bbox_inches="tight"
)

plt.close()
