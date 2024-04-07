# -*- coding: utf-8 -*-
# from odoo import http


# class Augusto(http.Controller):
#     @http.route('/augusto/augusto', auth='public')
#     def index(self, **kw):
#         return "Hello, world"

#     @http.route('/augusto/augusto/objects', auth='public')
#     def list(self, **kw):
#         return http.request.render('augusto.listing', {
#             'root': '/augusto/augusto',
#             'objects': http.request.env['augusto.augusto'].search([]),
#         })

#     @http.route('/augusto/augusto/objects/<model("augusto.augusto"):obj>', auth='public')
#     def object(self, obj, **kw):
#         return http.request.render('augusto.object', {
#             'object': obj
#         })

