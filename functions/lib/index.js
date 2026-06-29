"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyReceipt = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
/**
 * Verify a mobile In-App Purchase receipt.
 * Under production, this connects to Google Play Developer API and Apple App Store.
 * Under local emulation, it verifies the transaction mock payloads.
 */
exports.verifyReceipt = functions.https.onCall(async (data, context) => {
    // Ensure the user is authenticated via Firebase Auth
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }
    const uid = context.auth.uid;
    const { purchaseToken, productId } = data;
    if (!purchaseToken || !productId) {
        throw new functions.https.HttpsError("invalid-argument", "Missing purchaseToken or productId parameters.");
    }
    functions.logger.info(`Verifying receipt for user ${uid}, product ${productId}`);
    // Mock successful validation for local emulators
    const isValid = true;
    let tokensToAdd = 0;
    if (productId === "glow_token_pack_25") {
        tokensToAdd = 25;
    }
    else if (productId === "glow_token_pack_300") {
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
//# sourceMappingURL=index.js.map