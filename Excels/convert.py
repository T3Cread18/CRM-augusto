import pandas as pd

# Cargar los archivos Excel
df_customers = pd.read_excel('Customers.xlsx')
df_bill = pd.read_excel('bill.xlsx')

# Fusionar los DataFrames en uno nuevo basado en el nombre del cliente
df_merged = pd.merge(df_bill, df_customers, how='left', on='Customer Name')

# Guardar el resultado en un nuevo archivo Excel
df_merged.to_excel('ventas_con_informacion_adicional.xlsx', index=False)