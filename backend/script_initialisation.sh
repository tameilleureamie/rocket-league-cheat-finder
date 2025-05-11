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
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt ./
RUN apt-get update && apt-get install -y build-essential && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

COPY . .

CMD ["python", "main.py"]
EOF

# --- backend code ---
cat <<EOF > main.py
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import shutil, os
from carball.analysis.analysis_manager import AnalysisManager
import uvicorn

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

    manager = AnalysisManager(file_location)
    proto = manager.get_protobuf_data()
    df = manager.get_data_frame()

    touches = df['ball']['player_hits'][player].shape[0] if player in df['ball']['player_hits'] else 0
    bot_score = 100 if touches > 50 else 20
    result = "bot" if bot_score > 80 else "human" if bot_score < 40 else "suspect"
    return {"score": bot_score, "result": result}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
EOF

cat <<EOF > requirements.txt
fastapi
uvicorn
python-multipart
carball
EOF

cd ../..

echo "✅ Backend Docker prêt. Tu peux maintenant le lancer avec :"
echo "cd \$HOME/$PROJECT_NAME/backend"
echo "docker build -t rocket-backend ."
echo "docker run -p 8000:8000 rocket-backend"
echo "➡️ API disponible sur http://localhost:8000/analyze"
