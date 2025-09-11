from django.urls import path
from . import views

app_name = 'notes'

urlpatterns = [
    path('', views.note_list, name='note_list'),
    path('<int:note_id>/', views.note_detail, name='note_detail'),
    path('<int:note_id>/reprocess/', views.reprocess_note, name='reprocess_note'),
    path('search/', views.search_notes, name='search_notes'),
]
