import os
import json
from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google import genai
from google.genai import types

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

class PredictionResponse(BaseModel):
    primary_guess: str
    alternatives: list[str]
    confidence_score: float

@app.post("/predict", response_model=PredictionResponse)
async def predict_word(context: str = Form(...), audio: UploadFile = File(...)):
    temp_audio_path = None
    uploaded_file = None
    try:
        audio_bytes = await audio.read()

        temp_audio_path = f"temp_vyanjak_{os.getpid()}_{audio.filename}"
        with open(temp_audio_path, "wb") as f:
            f.write(audio_bytes)

        uploaded_file = client.files.upload(file=temp_audio_path)

        prompt = f"Environmental Context: {context}\nAnalyze the audio struggle and context to predict the target word."

        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt, uploaded_file],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=PredictionResponse,
                temperature=0.1,
                system_instruction="You are a cognitive prosthetic assisting a stroke survivor with Anomic Aphasia. Listen to the audio and read the environmental context. Predict the exact object they are trying to say. Output ONLY valid JSON matching the schema. Primary guess MUST be uppercase."
            )
        )

        result_dict = json.loads(response.text)
        return result_dict

    except Exception as e:
        print(f"CRITICAL ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        if temp_audio_path and os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)
        if uploaded_file:
            try:
                client.files.delete(name=uploaded_file.name)
            except Exception:
                pass