from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView
from authentication import views as auth_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('authentication.urls')),
    path('accounts/login/', auth_views.login_view, name='login'),
    # Update this to use the new home page URL
    path('', RedirectView.as_view(url='/auth/home/', permanent=False), name='home'),
]