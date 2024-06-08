import pandas as pd
import odoorpc

# Conectar a Odoo
odoo = odoorpc.ODOO('localhost', port=8069)
odoo.login('data', 'admin', 'Admin123!')

# Leer el archivo Excel
df = pd.read_excel('Merged_Comments.xlsx')

# Obtener el modelo sale.order
SaleOrder = odoo.env['sale.order']

for index, row in df.iterrows():
    sale_order_name = row['sale_order_name']
    new_description = row['Description']
    
    # Buscar la orden de venta por nombre
    sale_order_id = SaleOrder.search([('name', '=', sale_order_name)])
    
    if sale_order_id:
        # Obtener el registro de la orden de venta
        sale_order = SaleOrder.browse(sale_order_id[0])
        
        # Anexar la nueva descripción a la existente
        updated_description = new_description
        
        # Actualizar el campo de descripción
        SaleOrder.write(sale_order.id, {'internal_description': updated_description})