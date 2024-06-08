import pandas as pd

# Cargar los dos archivos Excel
df_nombres_clientes = pd.read_excel('bill_enero.xlsx', usecols=['name'])
df_datos_clientes = pd.read_excel('res_partner.xlsx')

# Realizar la búsqueda basada en los nombres de los clientes y combinar los datos
df_resultado = pd.merge(df_nombres_clientes, df_datos_clientes, how='left', left_on='name', right_on='name')

# Guardar el resultado en un nuevo archivo Excel
df_resultado.to_excel('resultado_completo.xlsx', index=False)