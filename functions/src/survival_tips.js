const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { VertexAI } = require('@google-cloud/vertexai');

const PROMPTS = {
  id: (amount, days) =>
    `Kamu adalah asisten keuangan Penyintas untuk mahasiswa dan pekerja perantau Indonesia.
Berikan tepat 5 tips hemat praktis untuk seseorang dengan sisa Rp ${amount} untuk ${days} hari ke depan.
Tone: hangat, jujur, tidak menghakimi. Sapaan "kamu". Bahasa Indonesia santai-formal.
Jangan menyalahkan keputusan masa lalu. Fokus pada apa yang bisa dilakukan sekarang.

Return JSON array persis (tanpa markdown, tanpa kode block):
[
  { "title": "...", "description": "1 kalimat saja.", "estimatedSaving": <angka dalam rupiah per hari> },
  ...
]`,

  en: (amount, days) =>
    `You are a financial assistant for overseas students and workers.
Give exactly 5 practical saving tips for someone with ${amount} IDR remaining for ${days} days.
Tone: warm, honest, non-judgmental. Focus on actionable steps.

Return a JSON array only (no markdown, no code block):
[
  { "title": "...", "description": "1 sentence only.", "estimatedSaving": <number in IDR per day> },
  ...
]`,

  ms: (amount, days) =>
    `Anda adalah pembantu kewangan untuk pelajar dan pekerja perantau.
Berikan tepat 5 tips berjimat praktikal untuk seseorang dengan baki Rp ${amount} untuk ${days} hari.
Nada: mesra, jujur, tidak menghakimi. Fokus pada langkah yang boleh dilakukan sekarang.

Return JSON array sahaja (tanpa markdown):
[
  { "title": "...", "description": "1 ayat sahaja.", "estimatedSaving": <nombor dalam rupiah sehari> },
  ...
]`,
};

function safeParseJson(raw) {
  const clean = raw
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/, '')
    .replace(/\s*```$/, '')
    .trim();
  return JSON.parse(clean);
}

exports.getSurvivalTips = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Login dulu.');

  const { amountCents, days, language = 'id' } = request.data;
  if (!amountCents || !days) {
    throw new HttpsError('invalid-argument', 'amountCents dan days wajib diisi.');
  }

  const uid = request.auth.uid;

  // Cache per bracket agar hemat quota AI
  // Bracket 50rb untuk amount, 3 hari untuk days
  const amountBracket = Math.floor(amountCents / 50000) * 50000;
  const daysBracket = Math.ceil(days / 3) * 3;
  const cacheKey = `${amountBracket}_${daysBracket}_${language}`;

  const db = getFirestore();
  const cacheRef = db.doc(`users/${uid}/survival_tips/${cacheKey}`);
  const cached = await cacheRef.get();

  if (cached.exists) {
    const data = cached.data();
    const cachedAt = data.cachedAt?.toDate?.() ?? new Date(0);
    // TTL 24 jam
    if (Date.now() - cachedAt.getTime() < 24 * 60 * 60 * 1000) {
      return { tips: data.tips };
    }
  }

  const promptFn = PROMPTS[language] ?? PROMPTS.id;
  const prompt = promptFn(amountCents, days);

  const vertexAI = new VertexAI({ project: process.env.GCLOUD_PROJECT });
  const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
  const result = await model.generateContent(prompt);

  const candidates = result?.response?.candidates;
  if (!candidates || candidates.length === 0) {
    throw new HttpsError('internal', 'AI tidak menghasilkan respons. Coba lagi.');
  }
  const text = candidates[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new HttpsError('internal', 'Format respons AI tidak dikenali. Coba lagi.');
  }

  let tips;
  try {
    tips = safeParseJson(text);
    if (!Array.isArray(tips)) throw new Error('Expected array');
  } catch (e) {
    throw new HttpsError('internal', 'Gagal memproses respons AI. Coba lagi.');
  }

  await cacheRef.set({ tips, cachedAt: FieldValue.serverTimestamp() });

  return { tips };
});
