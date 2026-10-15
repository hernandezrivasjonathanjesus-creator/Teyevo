import flet as ft
from database.login_view import LoginView
from database.home_view import HomeView
from database.turistic_view import TuristicView
from utils.auth import AuthService

def main(page: ft.Page):
    # Configuración de la página
    page.title = "TEYEVO - Sistema de Transporte"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.window.width = 1024
    page.window.height = 768
    page.window.resizable = True
    page.window.center()
    
    # Limpiar pantalla
    def clear():
        page.controls.clear()
    
    # Función para cambiar de vista
    def route_change(route):
        clear()
        
        # Verificar autenticación
        user = page.session.get("user")
        
        # Rutas públicas
        if page.route == "/login":
            view = LoginView(page)
            page.add(view.build())
        
        elif page.route == "/register":
            page.add(ft.Text("Registro - Próximamente", size=24))
        
        # Rutas privadas (requieren autenticación)
        elif user:
            if page.route == "/home":
                view = HomeView(page)
                page.add(view.build())
            
            elif page.route == "/turistic":
                view = TuristicView(page)
                page.add(view.build())
            
            elif page.route == "/viajes":
                page.add(ft.Text("Mis Viajes - Próximamente", size=24))
            
            elif page.route == "/perfil":
                page.add(ft.Text("Perfil de Usuario - Próximamente", size=24))
            
            else:
                page.go("/home")
        
        else:
            page.go("/login")
        
        page.update()
    
    # Manejar cambio de ruta
    def view_pop(view):
        page.views.pop()
        top_view = page.views[-1]
        page.go(top_view.route)
    
    page.on_route_change = route_change
    page.on_view_pop = view_pop
    
    # Ir a la página de login por defecto
    page.go("/login")

if __name__ == "__main__":
    ft.app(target=main)