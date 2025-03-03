from django.contrib import admin
from django.urls import path, include
from django.views.generic import RedirectView  # Import this if you want to redirect

urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('authentication.urls')),
    
    # Add a URL pattern for the root path. Choose one of these options:
    
    # Option 1: Redirect to the auth page
    path('', RedirectView.as_view(url='/auth/', permanent=False)),
    
    # Option 2: If you have a home view in one of your apps
    # path('', home_view, name='home'),
]