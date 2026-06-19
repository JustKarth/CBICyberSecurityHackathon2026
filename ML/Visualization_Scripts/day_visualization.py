import pandas as pd
import matplotlib.pyplot as plt

# Load data
train_transaction = pd.read_csv("train_transaction.csv")

# Day number since start
train_transaction['Day'] = train_transaction['TransactionDT'] // 86400

# Weekday (1-7)
train_transaction['WeekDay'] = (train_transaction['Day'] % 7) + 1

# Total transactions per weekday
txn_counts = (
    train_transaction
    .groupby('WeekDay')
    .size()
)

# Fraud counts per weekday
fraud_counts = (
    train_transaction[train_transaction['isFraud'] == 1]
    .groupby('WeekDay')
    .size()
)

# Combine
stats = pd.DataFrame({
    'Transactions': txn_counts,
    'Frauds': fraud_counts
}).fillna(0)

# Fraud %
stats['FraudPercent'] = (
    stats['Frauds'] / stats['Transactions']
) * 100

# Plot
fig, ax1 = plt.subplots(figsize=(12, 6))

# Bars: transaction counts
ax1.bar(
    stats.index,
    stats['Transactions']
)

ax1.set_xlabel('Day of Week (1-7)')
ax1.set_ylabel('Number of Transactions')

# Second axis: fraud %
ax2 = ax1.twinx()

ax2.plot(
    stats.index,
    stats['FraudPercent'],
    marker='o',
    color = 'r',
    linewidth=3
)

ax2.set_ylabel('Fraud Percentage (%)')

plt.title('Transactions and Fraud Rate by Day of Week')

plt.tight_layout()

plt.savefig(
    'weekday_transactions_fraudrate.png',
    dpi=300,
    bbox_inches='tight'
)

plt.close()

print(stats)
