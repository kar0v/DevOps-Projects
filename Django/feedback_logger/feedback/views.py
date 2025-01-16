from django.shortcuts import render, redirect, get_object_or_404
from django.http import HttpResponse, FileResponse, HttpResponseNotFound
from .models import Feedback
from django.conf import settings
import os
import logging

logger = logging.getLogger('application')


def feedback_form(request):
    if request.method == 'POST':
        name = request.POST['name']
        email = request.POST['email']
        message = request.POST['message']
        attachment = request.FILES.get('attachment')
        feedback = Feedback(name=name, email=email, message=message, attachment=attachment)
        feedback.save()
        logger.info(f"Added Feedback | File: {attachment.name if attachment else 'No file'} | Email: {email}")
        return render(request, 'feedback/feedback_success.html', {'name': name})
    return render(request, 'feedback/feedback_form.html')


def feedback_list(request):
    feedbacks = Feedback.objects.all().order_by('-created_at')
    return render(request, 'feedback/feedback_list.html', {'feedbacks': feedbacks})

def landing_page(request):
    return render(request, 'landing_page.html')

def serve_media(request, path):
    file_path = os.path.join(settings.MEDIA_ROOT, path)
    if os.path.exists(file_path):
        return FileResponse(open(file_path, 'rb'), as_attachment=True)
    else:
        return HttpResponseNotFound("File not found.")

def delete_feedback(request, feedback_id):
    feedback = get_object_or_404(Feedback, id=feedback_id)
    if request.method == 'POST':
        feedback.delete()  
        return redirect('feedback_list')  
    return render(request, 'feedback/delete_feedback.html', {'feedback': feedback})


def update_feedback(request, feedback_id):
    # Get the feedback object or return 404 if not found
    feedback = get_object_or_404(Feedback, id=feedback_id)
    if request.method == 'POST':
        feedback.message = request.POST.get('message')
        feedback.save()  
        logger.info(f"Updated Feedback | Email: {feedback.email} | Old Message: {old_message} | New Message: {feedback.message}")
        return redirect('feedback_list') 
    return render(request, 'feedback/update_feedback.html', {'feedback': feedback})
