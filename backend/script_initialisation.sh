#!/bin/bash

# 🚀 Script de déploiement Docker Rocket League Cheat Finder (backend only)

set -e

PROJECT_NAME="rocket-league-cheat-finder"
REPO_DIR="$HOME/$PROJECT_NAME"
BACKEND_URL="http://localhost:8000/analyze"

mkdir -p "$REPO_DIR/backend"
cd "$REPO_DIR/backend"

# --- Dockerfile ---
cat <<EOF > Dockerfile
FROM python:3.8

WORKDIR /app

COPY backend/requirements.txt ./
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY backend/ .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# --- backend code ---
cat <<EOF > main.py
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import shutil, os
from carball.analysis.analysis_manager import AnalysisManager

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

@app.post("/players")
async def list_players(replay: UploadFile = File(...)):
    file_location = f"./temp/{replay.filename}"
    os.makedirs("./temp", exist_ok=True)
    with open(file_location, "wb") as f:
        shutil.copyfileobj(replay.file, f)

    try:
        manager = AnalysisManager(file_location)
        df = manager.get_data_frame()
        players = list(df['ball']['player_hits'].keys())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse du fichier: {str(e)}")

    return {"players": players}

@app.post("/analyze")
async def analyze_replay(replay: UploadFile = File(...), player: str = Form(...)):
    file_location = f"./temp/{replay.filename}"
    os.makedirs("./temp", exist_ok=True)
    with open(file_location, "wb") as f:
        shutil.copyfileobj(replay.file, f)

    try:
        manager = AnalysisManager(file_location)
        df = manager.get_data_frame()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse du fichier: {str(e)}")

    if not df or 'ball' not in df or 'player_hits' not in df['ball']:
        raise HTTPException(status_code=500, detail="Structure du fichier non conforme ou vide.")

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
EOF

cat <<EOF > requirements.txt
numpy==1.18.2
pandas==1.0.3
protobuf==3.6.1
fastapi==0.95.2
uvicorn==0.22.0
python-multipart==0.0.6
carball==0.7.5
EOF

cd ../..

echo "✅ Backend Docker prêt. Tu peux maintenant le lancer avec :"
echo "cd \$HOME/$PROJECT_NAME/backend"
echo "docker build -t rocket-backend ."
echo "docker run -p 8000:8000 rocket-backend"
echo "➡️ API disponible sur http://localhost:8000/analyze"
echo "➡️ Endpoint pour obtenir les joueurs : http://localhost:8000/players"
