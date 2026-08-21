import os
from groq import Groq
from gtts import gTTS
from core.config import settings
import uuid

class VoiceEngine:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY", settings.GROQ_API_KEY)
        if self.api_key:
            self.client = Groq(api_key=self.api_key)
        else:
            self.client = None
            
        # Ensure audio cache directory exists
        self.audio_cache_dir = "temp_audio"
        os.makedirs(self.audio_cache_dir, exist_ok=True)

    def transcribe_audio(self, file_path: str) -> str:
        """Transcribes an audio file to text using Groq's insanely fast Whisper API."""
        if not self.client:
            return "Error: GROQ_API_KEY is not configured."
            
        print(f"Transcribing {file_path} with Groq Whisper...")
        with open(file_path, "rb") as file:
            transcription = self.client.audio.transcriptions.create(
                file=(os.path.basename(file_path), file.read()),
                model="whisper-large-v3",
                prompt="The audio is a user asking a question about their study notes.",
                response_format="text",
            )
        print(f"Transcription: {transcription}")
        return transcription

    def generate_speech(self, text: str) -> str:
        """Converts text to speech using Google TTS and returns the file path."""
        print("Generating TTS with gTTS...")
        tts = gTTS(text=text, lang='en', slow=False)
        output_file = os.path.join(self.audio_cache_dir, f"{uuid.uuid4()}.mp3")
        tts.save(output_file)
        print(f"Saved TTS to {output_file}")
        return output_file

voice_engine = VoiceEngine()
