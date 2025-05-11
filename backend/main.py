from fastapi import FastAPI, File, Form, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil, os
from carball.analysis.analysis_manager import AnalysisManager

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

@app.post("/analyze")
async def analyze_replay(replay: UploadFile = File(...), player: str = Form(...)):
    file_location = f"./temp/{replay.filename}"
    os.makedirs("./temp", exist_ok=True)

    with open(file_location, "wb") as f:
        shutil.copyfileobj(replay.file, f)

    try:
        manager = AnalysisManager(file_location)
        proto = manager.get_protobuf_data()
        df = manager.get_data_frame()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse du fichier: {str(e)}")

    if player not in df['ball']['player_hits']:
        available_players = list(df['ball']['player_hits'].keys())
        raise HTTPException(
            status_code=404,
            detail=f"Joueur '{player}' introuvable. Joueurs disponibles : {available_players}"
        )

    touches = df['ball']['player_hits'][player].shape[0]
    bot_score = 100 if touches > 50 else 20
    result = "bot" if bot_score > 80 else "human" if bot_score < 40 else "suspect"
    return {"score": bot_score, "result": result}
