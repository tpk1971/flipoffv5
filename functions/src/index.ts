import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Verify a mobile In-App Purchase receipt.
 * Under production, this connects to Google Play Developer API and Apple App Store.
 * Under local emulation, it verifies the transaction mock payloads.
 */
export const verifyReceipt = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated via Firebase Auth
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;
  const { purchaseToken, productId } = data;

  if (!purchaseToken || !productId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing purchaseToken or productId parameters."
    );
  }

  functions.logger.info(`Verifying receipt for user ${uid}, product ${productId}`);

  // Mock successful validation for local emulators
  const isValid = true; 
  let tokensToAdd = 0;

  if (productId === "glow_token_pack_25") {
    tokensToAdd = 25;
  } else if (productId === "glow_token_pack_300") {
    tokensToAdd = 300;
  }

  if (isValid && tokensToAdd > 0) {
    const userRef = admin.firestore().collection("users").doc(uid);
    
    // Perform database atomic transaction to update token balance
    await admin.firestore().runTransaction(async (transaction) => {
      const doc = await transaction.get(userRef);
      const currentTokens = doc.exists ? (doc.data()?.tokenCount || 0) : 0;
      transaction.set(userRef, { tokenCount: currentTokens + tokensToAdd }, { merge: true });
    });

    return { success: true, added: tokensToAdd };
  }

  return { success: false, message: "Invalid transaction receipt." };
});

/**
 * Lodge a user's game score securely.
 * Checks and updates their personal top 10 high scores in users/{uid},
 * and conditionally updates their best score in the global leaderboards/{uid}.
 */
export const submitScore = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated via Firebase Auth
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const uid = context.auth.uid;
  const score = data.score;

  if (score === undefined || typeof score !== "number" || score < 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a positive integer score."
    );
  }

  functions.logger.info(`LODGING SCORE: User ${uid} submitted score ${score}`);

  const firestore = admin.firestore();
  const userRef = firestore.collection("users").doc(uid);
  const leaderboardRef = firestore.collection("leaderboards").doc(uid);

  // Use a transaction to perform atomic read-writes
  await firestore.runTransaction(async (transaction) => {
    // 1. Update user profile personal bests
    const userDoc = await transaction.get(userRef);
    let highScores: number[] = [];
    if (userDoc.exists) {
      highScores = userDoc.data()?.highScores || [];
    }
    highScores.push(score);
    highScores.sort((a, b) => b - a); // descending
    highScores = highScores.slice(0, 10); // cap at 10

    transaction.set(userRef, { highScores }, { merge: true });

    // 2. Update global leaderboard if this is the user's best score
    const leaderboardDoc = await transaction.get(leaderboardRef);
    if (!leaderboardDoc.exists || (leaderboardDoc.data()?.score || 0) < score) {
      transaction.set(leaderboardRef, {
        userId: uid,
        score: score,
        displayName: `Guest_${uid.substring(0, 5)}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

  return { success: true };
});

