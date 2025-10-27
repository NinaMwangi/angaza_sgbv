/**
 * Triggered when a new audio file is uploaded.
 * Converts speech → text using Whisper, then writes transcript to Firestore.
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");

admin.initializeApp();
const db = admin.firestore();
const openai = new OpenAI({ apiKey: functions.config().openai.key });

exports.transcribeAudio = functions.storage
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;          // e.g. audio/{userId}/{incidentId}.m4a
    if (!filePath || !filePath.startsWith("audio/")) return null;

    const pathParts = filePath.split("/");
    if (pathParts.length < 3) return null;

    const userId = pathParts[1];
    const fileName = pathParts[2];
    const incidentId = fileName.replace(".m4a", "");

    try {
      // Download the file to temp
      const bucket = admin.storage().bucket(object.bucket);
      const tempFile = `/tmp/${fileName}`;
      await bucket.file(filePath).download({ destination: tempFile });

      // Transcribe with Whisper
      const resp = await openai.audio.transcriptions.create({
        file: require("fs").createReadStream(tempFile),
        model: "whisper-1",
        language: "sw",          // Swahili supported
        response_format: "text",
      });

      const transcript = resp.text || resp.data || "";

      // Write transcript back to Firestore
      await db.collection("incidents").doc(incidentId).set(
        {
          transcript: transcript,
          transcriptedAt: admin.firestore.FieldValue.serverTimestamp(),
          transcriptSource: "whisper",
        },
        { merge: true },
      );

      console.log(`✅ Transcribed ${incidentId} (${transcript.length} chars)`);
    } catch (err) {
      console.error("❌ ASR Error:", err);
      await db.collection("incidents").doc(incidentId).set(
        {
          transcriptError: err.message,
        },
        { merge: true },
      );
    }
    return null;
  });
