# What is highly correlated with gross field

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

plt.style.use('ggplot')

# To review all the data frame, let's set all columns can be shown
pd.set_option('display.max_columns', None)

# Also below code is to review all rows but I don't need it here
pd.set_option('display.max_rows', None)

# read in the data
df = pd.read_csv("movies.csv", encoding='cp1252')

# use Panda to clean up the data first
# Let's see if there is any missing data
for col in df.columns:
    percent_missing = np.mean(df[col].isnull()) / len(col)
    print('{} - {}%'.format(col, percent_missing))

# Modify Data type for our columns
# .0 is not necessary in some float columns so modify them into int
df['budget'] = df['budget'].astype('int64')
df['gross'] = df['gross'].astype('int64')

# release by date should be match with year of release but some are not matching
# Let's modify the table by adding a new column
df['year_corrected'] = df['released'].astype('string').str[:4]

# sort data by gross
df = df.sort_values(by=['gross'], inplace=False, ascending=False)

# Check if some company names are needed to be append
df['company'].drop_duplicates().sort_values(ascending=False)
# Drop any duplicates
df.drop_duplicates()

# What fields are most correlated with Gross
# Assumption: Budget VS Gross
plt.scatter(x=df['budget'], y=df['gross'])
plt.title('Budget Vs Gross Earnings')
plt.xlabel('Gross Earning')
plt.ylabel('Budget for Film')
plt.savefig('BudgetVSGross.png')

# Plot budget VS gross using seaborn
sns.regplot(x='budget', y='gross', data=df, scatter_kws={"color": "red"}, line_kws={"color": "blue"})
plt.show()

# Let's start to look at correlation
# first among numeric data
correlation_matrix = df.corr()  # methods: pearson(default), kendall, spearman
print(correlation_matrix)

sns.heatmap(correlation_matrix, annot=True)
plt.title('Correlation Matrix for Numeric Features')
plt.xlabel('Movie Features')
plt.ylabel('Movie Featrues')
plt.show()
# comment: High correlation between budget and gross and votes and gross

# Look at categorical data
# assign some numeric value to categorical data
df_numerized = df

for col_name in df_numerized.columns:
    if df_numerized[col_name].dtype == 'object':
        df_numerized[col_name] = df_numerized[col_name].astype("category")
        df_numerized[col_name] = df_numerized[col_name].cat.codes

# Correlation of all data
correlation_matrix = df_numerized.corr()  # methods: pearson(default), kendall, spearman
print(correlation_matrix)

sns.heatmap(correlation_matrix, annot=True)
plt.title('Correlation Matrix for Numeric Features')
plt.xlabel('Movie Features')
plt.ylabel('Movie Features')
plt.show()

sorted_correlation_pairs = correlation_matrix.unstack().sort_values()
high_corr = sorted_correlation_pairs[((sorted_correlation_pairs > 0.5) & (sorted_correlation_pairs != 1))
                                     | ((sorted_correlation_pairs < (-0.5)) & (sorted_correlation_pairs != -1))]
print(high_corr)
