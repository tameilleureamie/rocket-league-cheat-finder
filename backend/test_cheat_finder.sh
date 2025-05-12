#!/bin/bash

REPLAY_FILE="D0B43FC942ED582418ADFC846A8C9E19.replay"
BACKEND_URL="https://rocket-league-cheat-finder.onrender.com"

echo "📤 Upload du fichier..."
response=$(curl -s -X POST "$BACKEND_URL/upload" \
  -F "replay=@$REPLAY_FILE")

echo "📦 Réponse :"
echo "$response"

echo ""
echo "📝 Étape suivante manuelle : copie le session_id et un nom de joueur"
echo "Et lance la commande suivante :"
echo ""
echo "curl -X POST $BACKEND_URL/analyze -F 'session_id=TON_SESSION_ID' -F 'player=TON_JOUEUR'"
