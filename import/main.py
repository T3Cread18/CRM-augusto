import pandas as pd

# Cargar los archivos Excel
df_bill = pd.read_excel('enero.xlsx')
df_res_partner = pd.read_excel('res_partner.xlsx')

# Eliminar espacios en blanco al final de las celdas en df_res_partner
df_res_partner['name'] = df_res_partner['name'].str.strip()

# Crear un diccionario que mapee nombres a ID
id_mapping = dict(zip(df_res_partner['name'], df_res_partner['id']))

# Reemplazar el nombre por el ID en df_bill
df_bill['name'] = df_bill['name'].str.strip().map(id_mapping)

# Guardar el resultado en un nuevo archivo Excel
df_bill.to_excel('bill_enero.xlsx', index=False)