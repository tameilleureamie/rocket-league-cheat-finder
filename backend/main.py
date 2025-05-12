from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil, os, uuid
from carball.analysis.analysis_manager import AnalysisManager

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

SESSIONS = {}

@app.post("/analyze")
async def analyze(replay: UploadFile = File(None), session_id: str = Form(None), player: str = Form(...)):
    if replay is not None:
        session_id = str(uuid.uuid4())
        file_loc = f"./temp/{session_id}_{replay.filename}"
        os.makedirs("./temp", exist_ok=True)

        with open(file_loc, 'wb') as f:
            shutil.copyfileobj(replay.file, f)

        try:
            manager = AnalysisManager(file_loc)
            df = manager.get_data_frame()
            if not isinstance(df, dict) or 'ball' not in df or 'player_hits' not in df['ball']:
                raise ValueError("Données invalides extraites du fichier.")
            players = list(df['ball']['player_hits'].keys())
            SESSIONS[session_id] = {'file': file_loc, 'players': players}
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Erreur d'analyse: {e}")

        return {'session_id': session_id, 'players': players}

    # Analyse d'une session existante
    if not session_id:
        raise HTTPException(status_code=400, detail="session_id ou replay requis.")

    session = SESSIONS.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable. Uploade d'abord via replay.")

    file_loc = session['file']
    if not os.path.exists(file_loc):
        raise HTTPException(status_code=500, detail="Fichier replay manquant. Session expirée.")

    try:
        manager = AnalysisManager(file_loc)
        df = manager.get_data_frame()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'analyse: {e}")

    if player not in df['ball']['player_hits']:
        raise HTTPException(status_code=404, detail=f"Joueur '{player}' introuvable dans le replay. Joueurs disponibles : {session['players']}")

    touches = df['ball']['player_hits'][player].shape[0]
    score = 100 if touches > 50 else 20
    result = "bot" if score > 80 else "human" if score < 40 else "suspect"

    return {'score': score, 'result': result}
