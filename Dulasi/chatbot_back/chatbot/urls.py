#All project URLs go here
#http://127.0.0.1:8000/

from django.urls import path #paths
from . import views #our own views.py

urlpatterns = [
    #path(addition to the current url, render, url name)
    path('', views.chatbot, name='chatbot'),
]