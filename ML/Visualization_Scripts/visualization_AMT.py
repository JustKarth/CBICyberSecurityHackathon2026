import pandas as pd
import matplotlib.pyplot as plt


train_transaction = pd.read_csv("train_transaction.csv")
ts_df = train_transaction[['TransactionDT', 'TransactionAmt']].copy()
ts_df['Day'] = ts_df['TransactionDT'] // 86400

daily_amt = (
    ts_df.groupby('Day')['TransactionAmt']
    .mean()
    .reset_index()
)

plt.figure(figsize=(14,6))
plt.plot(daily_amt['Day'], daily_amt['TransactionAmt'])

plt.title("Average Transaction Amount Over Time")
plt.xlabel("Day")
plt.ylabel("Average Transaction Amount")
plt.grid(True)

plt.savefig("transaction_amount_timeseries.png", dpi=300)