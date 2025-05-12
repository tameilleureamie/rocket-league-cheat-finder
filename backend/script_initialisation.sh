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
import shutil, os, uuid
from carball.analysis.analysis_manager import AnalysisManager

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

SESSIONS = {}

@app.post("/upload")
async def upload_replay(replay: UploadFile = File(...)):
    session_id = str(uuid.uuid4())
    file_location = f"./temp/{session_id}_{replay.filename}"
    os.makedirs("./temp", exist_ok=True)
    with open(file_location, "wb") as f:
        shutil.copyfileobj(replay.file, f)

    try:
        manager = AnalysisManager(file_location)
        df = manager.get_data_frame()
        players = list(df['ball']['player_hits'].keys())
        SESSIONS[session_id] = {"file": file_location, "players": players}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse du fichier: {str(e)}")

    return {"session_id": session_id, "players": players}

@app.post("/analyze")
async def analyze_player(session_id: str = Form(...), player: str = Form(...)):
    session = SESSIONS.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session non trouvée. Veuillez d'abord téléverser un fichier via /upload.")

    file_location = session.get("file")
    if not file_location or not os.path.exists(file_location):
        raise HTTPException(status_code=500, detail="Fichier replay introuvable sur le serveur. La session est peut-être expirée.")

    try:
        manager = AnalysisManager(file_location)
        df = manager.get_data_frame()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse du fichier: {str(e)}")

    if player not in df['ball']['player_hits']:
        raise HTTPException(status_code=404, detail="Joueur introuvable dans ce replay.")

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

# --- script test simplifié sans jq ---
cat <<EOF > test_cheat_finder.sh
#!/bin/bash

REPLAY_FILE="D0B43FC942ED582418ADFC846A8C9E19.replay"
BACKEND_URL="https://rocket-league-cheat-finder.onrender.com"

echo "📤 Upload du fichier..."
response=$(curl -s -X POST "$BACKEND_URL/upload" \
  -F "replay=@\$REPLAY_FILE")

echo "📦 Réponse :"
echo "\$response"

echo "📝 Copie manuelle du session_id et du nom du joueur pour l'analyse"
echo "Utilise ensuite cette commande :"
echo "curl -X POST \$BACKEND_URL/analyze -F 'session_id=TON_SESSION_ID' -F 'player=TON_JOUEUR'"
EOF

chmod +x test_cheat_finder.sh

cd ../..

echo "✅ Backend Docker prêt. Tu peux maintenant le lancer avec :"
echo "cd \$HOME/$PROJECT_NAME/backend"
echo "docker build -t rocket-backend ."
echo "docker run -p 8000:8000 rocket-backend"
echo "➡️ POST /upload : envoie le .replay et reçois session_id + joueurs"
echo "➡️ POST /analyze : envoie session_id + joueur pour analyser"
echo "🧪 Pour tester rapidement : ./backend/test_cheat_finder.sh"
