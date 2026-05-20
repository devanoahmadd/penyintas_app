const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { VertexAI } = require('@google-cloud/vertexai');

function safeParseJson(raw) {
  const clean = raw
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/, '')
    .replace(/\s*```$/, '')
    .trim();
  return JSON.parse(clean);
}

exports.generateInsight = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login dulu.');

  const uid = request.auth.uid;
  const { transactions, budgetSettings } = request.data;

  // #87: gunakan month dari client (format '2026-5') bukan getMonth() yang 0-indexed
  const cacheKey = transactions?.month;
  if (!cacheKey) throw new HttpsError('invalid-argument', 'Data bulan tidak ditemukan.');

  const db = getFirestore();
  const cacheRef = db.doc(`users/${uid}/insights/${cacheKey}`);
  const cached = await cacheRef.get();

  if (cached.exists) {
    const data = cached.data();
    const cachedAt = data.cachedAt?.toDate?.() ?? new Date(0);
    if (Date.now() - cachedAt.getTime() < 24 * 60 * 60 * 1000) {
      return { insights: data.insights, savingTip: data.savingTip };
    }
  }

  const prompt = `Kamu adalah asisten keuangan Penyintas untuk mahasiswa Indonesia.
Analisis data pengeluaran ini dan berikan 3 insight singkat dalam bahasa Indonesia santai (sapaan "kamu"). Setiap insight max 2 kalimat.
Tone: hangat, jujur, tidak menghakimi. Jangan lebay. Jangan jargon Inggris.

Data: ${JSON.stringify({ transactions, budgetSettings })}

Return JSON persis (tanpa markdown, tanpa kode block):
{ "insights": ["...", "...", "..."], "savingTip": "..." }`;

  const vertexAI = new VertexAI({ project: process.env.GCLOUD_PROJECT });
  const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
  const result = await model.generateContent(prompt);

  // #89: null guard — Vertex AI bisa return empty candidates saat safety filter / quota
  const candidates = result?.response?.candidates;
  if (!candidates || candidates.length === 0) {
    throw new HttpsError('internal', 'AI tidak menghasilkan respons. Coba lagi.');
  }
  const text = candidates[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new HttpsError('internal', 'Format respons AI tidak dikenali. Coba lagi.');
  }

  // #88: sanitasi markdown fence sebelum JSON.parse — LLM sering tambahkan ```json
  let parsed;
  try {
    parsed = safeParseJson(text);
  } catch (e) {
    throw new HttpsError('internal', 'Gagal memproses respons AI. Coba lagi.');
  }

  await cacheRef.set({
    insights: parsed.insights,
    savingTip: parsed.savingTip,
    cachedAt: FieldValue.serverTimestamp(),
  });

  return parsed;
});
