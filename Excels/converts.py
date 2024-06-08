import pandas as pd

# Leer el archivo Names.xlsx
names_df = pd.read_excel('Names.xlsx', header=None)
names_df.columns = ['customer_name']

# Leer el archivo Comments.xlsx
comments_df = pd.read_excel('Comments.xlsx', header=None)
comments_df.columns = ['customer_name', 'description']

# Unir los dos DataFrames basado en el nombre del cliente
merged_df = pd.merge(names_df, comments_df, on='customer_name', how='left')

# Guardar el resultado en un nuevo archivo Excel
merged_df.to_excel('Merged_Comments.xlsx', index=False, header=['Customer Name', 'Description'])