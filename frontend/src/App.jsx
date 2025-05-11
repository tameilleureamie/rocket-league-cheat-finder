import React, { useState } from "react";
import axios from "axios";

export default function App() {
  const [file, setFile] = useState(null);
  const [playerName, setPlayerName] = useState("");
  const [result, setResult] = useState(null);

  const handleUpload = async () => {
    const formData = new FormData();
    formData.append("replay", file);
    formData.append("player", playerName);

    const response = await axios.post("https://your-backend.onrender.com/analyze", formData);
    setResult(response.data);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-blue-800 text-white font-sans flex flex-col items-center justify-start py-12 px-4">
      <div className="max-w-xl w-full bg-white text-gray-900 rounded-2xl shadow-lg p-6">
        <h1 className="text-4xl font-bold mb-6 text-center text-blue-800">🚗 Rocket League Cheat Finder</h1>
        <input
          type="file"
          accept=".replay"
          onChange={(e) => setFile(e.target.files[0])}
          className="w-full mb-4 border border-gray-300 rounded px-3 py-2"
        />
        <input
          type="text"
          placeholder="Nom du joueur à analyser"
          value={playerName}
          onChange={(e) => setPlayerName(e.target.value)}
          className="w-full mb-4 border border-gray-300 rounded px-3 py-2"
        />
        <button
          onClick={handleUpload}
          className="w-full bg-blue-700 hover:bg-blue-900 text-white font-bold py-2 px-4 rounded"
        >
          Lancer l'analyse
        </button>

        {result && (
          <div className="mt-6 p-4 border rounded bg-gray-100 text-black">
            <h2 className="text-xl font-semibold">Résultat</h2>
            <p><strong>Score de suspicion :</strong> {result.score}</p>
            <p><strong>Bot ou pas ?</strong> {result.result}</p>
          </div>
        )}
      </div>
    </div>
  );
}
