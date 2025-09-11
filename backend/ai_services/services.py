import os
import json
import openai
from google.cloud import speech
from django.conf import settings


def transcribe_audio_google(audio_file_path):
    """
    Transcribe audio using Google Cloud Speech-to-Text
    """
    try:
        # Initialize the client
        client = speech.SpeechClient.from_service_account_json(
            settings.GOOGLE_CLOUD_SPEECH_CREDENTIALS_PATH
        ) if settings.GOOGLE_CLOUD_SPEECH_CREDENTIALS_PATH else speech.SpeechClient()
        
        # Load audio file
        with open(audio_file_path, 'rb') as audio_file:
            content = audio_file.read()
        
        audio = speech.RecognitionAudio(content=content)
        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.WEBM_OPUS,
            sample_rate_hertz=48000,
            language_code='en-US',
            enable_automatic_punctuation=True,
            enable_speaker_diarization=False,
        )
        
        # Perform the transcription
        response = client.recognize(config=config, audio=audio)
        
        # Extract transcription
        transcription = ''
        for result in response.results:
            transcription += result.alternatives[0].transcript + ' '
        
        return transcription.strip()
    
    except Exception as e:
        raise Exception(f"Speech-to-text failed: {str(e)}")


def generate_ai_content(raw_content):
    """
    Generate key points and detailed notes using OpenAI
    """
    try:
        client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)
        
        # Prompt for generating key points
        key_points_prompt = f"""
        Please analyze the following transcribed content and extract the key points as a JSON array of strings.
        Each key point should be concise (1-2 sentences) and capture the main ideas.
        
        Content: {raw_content}
        
        Return only a valid JSON array of strings, no additional text.
        """
        
        # Generate key points
        key_points_response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are an expert note-taking assistant. Extract key points from transcribed content and return them as a JSON array of strings."},
                {"role": "user", "content": key_points_prompt}
            ],
            max_tokens=500,
            temperature=0.3
        )
        
        # Prompt for generating detailed notes
        detailed_notes_prompt = f"""
        Please organize and structure the following transcribed content into detailed, well-formatted notes.
        Make the content more readable, add proper structure with headings and bullet points where appropriate,
        and ensure the information flows logically.
        
        Content: {raw_content}
        
        Return well-structured notes in markdown format.
        """
        
        # Generate detailed notes
        detailed_notes_response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are an expert note-taking assistant. Structure and organize transcribed content into clear, detailed notes."},
                {"role": "user", "content": detailed_notes_prompt}
            ],
            max_tokens=1500,
            temperature=0.3
        )
        
        # Parse key points response
        try:
            key_points_text = key_points_response.choices[0].message.content.strip()
            # Remove any markdown code block formatting
            if key_points_text.startswith('```'):
                key_points_text = key_points_text.split('\n', 1)[1]
            if key_points_text.endswith('```'):
                key_points_text = key_points_text.rsplit('\n', 1)[0]
            
            key_points = json.loads(key_points_text)
            if not isinstance(key_points, list):
                raise ValueError("Key points must be a list")
        except (json.JSONDecodeError, ValueError) as e:
            # Fallback: create simple bullet points
            key_points = [line.strip() for line in key_points_response.choices[0].message.content.split('\n') if line.strip()]
        
        detailed_notes = detailed_notes_response.choices[0].message.content.strip()
        
        return {
            'key_points': key_points,
            'detailed_notes': detailed_notes
        }
    
    except Exception as e:
        raise Exception(f"AI processing failed: {str(e)}")


def process_note_with_ai(note_id):
    """
    Process a note with AI to generate key points and detailed notes
    """
    from notes.models import Note
    
    try:
        note = Note.objects.get(id=note_id)
        note.processing_status = 'processing'
        note.save()
        
        if not note.raw_content:
            raise Exception("No raw content to process")
        
        # Generate AI content
        ai_content = generate_ai_content(note.raw_content)
        
        # Update note with AI-generated content
        note.key_points = ai_content['key_points']
        note.detailed_notes = ai_content['detailed_notes']
        note.processing_status = 'completed'
        note.save()
        
        return note
    
    except Exception as e:
        try:
            from notes.models import Note
            note = Note.objects.get(id=note_id)
            note.processing_status = 'failed'
            note.save()
        except:
            pass
        raise e


def process_audio_to_note(audio_file_path, note_id):
    """
    Complete pipeline: transcribe audio and process with AI
    """
    from notes.models import Note
    
    try:
        note = Note.objects.get(id=note_id)
        note.processing_status = 'transcribing'
        note.save()
        
        # Transcribe audio
        transcription = transcribe_audio_google(audio_file_path)
        
        # Update note with transcription
        note.raw_content = transcription
        note.audio_file_path = audio_file_path
        note.save()
        
        # Process with AI
        return process_note_with_ai(note_id)
    
    except Exception as e:
        try:
            note = Note.objects.get(id=note_id)
            note.processing_status = 'failed'
            note.save()
        except:
            pass
        raise e
