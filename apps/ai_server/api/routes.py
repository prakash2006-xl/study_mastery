from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import shutil
import os
from core.rag_engine import rag_engine
from core.voice_engine import voice_engine

router = APIRouter()

class AskRequest(BaseModel):
    document_id: str
    query: str

class SummarizeRequest(BaseModel):
    document_id: str

@router.post("/index_document")
async def index_document(document_id: str = Form(...), file: UploadFile = File(...)):
    # Save uploaded file to a temporary location for PyPDFLoader
    temp_dir = "temp_uploads"
    os.makedirs(temp_dir, exist_ok=True)
    temp_file_path = os.path.join(temp_dir, f"{document_id}.pdf")
    
    try:
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        chunks = rag_engine.index_pdf(document_id, temp_file_path)
        return {"status": "success", "chunks_indexed": chunks, "document_id": document_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Clean up temporary file if needed
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

@router.post("/ask_document")
async def ask_document(req: AskRequest):
    try:
        answer = rag_engine.ask_question(req.document_id, req.query)
        return {"answer": answer}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/voice_chat")
async def voice_chat(document_id: str = Form(...), file: UploadFile = File(...)):
    """Receives voice, transcribes it, runs RAG, and returns TTS audio."""
    temp_audio_path = os.path.join(voice_engine.audio_cache_dir, f"incoming_{file.filename}")
    
    try:
        with open(temp_audio_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Step 1: Transcribe audio to text
        transcript = voice_engine.transcribe_audio(temp_audio_path)
        if transcript.startswith("Error"):
            raise HTTPException(status_code=500, detail=transcript)
            
        # Step 2: RAG Pipeline to get answer
        answer = rag_engine.ask_question(document_id, transcript)
        
        # Step 3: Text to Speech
        response_audio_path = voice_engine.generate_speech(answer)
        
        return FileResponse(
            response_audio_path, 
            media_type="audio/mpeg", 
            filename="response.mp3",
            headers={"X-Transcript": transcript.replace('\n', ' ')}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)

@router.post("/summarize")
async def summarize_content(req: SummarizeRequest):
    return {"summary": "Generated summary of the provided content."}

@router.post("/speak")
async def speak_text(text: str):
    return {"audio_url": "/static/audio_sample.mp3"}
