const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");

// Set global options to use Mumbai region
setGlobalOptions({ region: "asia-south1" });

// Define the secret
const geminiApiKey = defineSecret("GEMINI_API_KEY");

exports.generateOverdueReminder = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // Check auth
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const { customerName, invoiceNumber, invoiceAmount, outstandingAmount, totalPartyBalance, daysLate, toneInstruction } = request.data;

    if (!customerName || !invoiceNumber || !invoiceAmount || !outstandingAmount || daysLate === undefined) {
        throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
        throw new HttpsError("failed-precondition", "Gemini API key is not configured in secrets.");
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-pro" });

    const prompt = `
You are "Outstanding Management App", an automated collections agent for a small business. 
Generate a professional WhatsApp/Email reminder message for a customer to pay their overdue invoice.

Context:
Customer Name: ${customerName}
Invoice Number: ${invoiceNumber}
Invoice Amount: ₹${invoiceAmount}
Outstanding Amount for this invoice: ₹${outstandingAmount}
Total Outstanding Balance for this customer: ₹${totalPartyBalance}
Days Overdue: ${daysLate}
${toneInstruction}

Instructions:
1. Make it sound human and professional.
2. If the tone instruction mentions including the total balance or invoice number, make sure they are included naturally.
3. Keep it brief and suitable for a WhatsApp message or short email.
4. Do NOT include placeholders like [Your Name] or [Company Name]. Just write the message body itself.
5. Provide ONLY the final message string, no extra conversational text or formatting outside the message.
  `;

    try {
        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();

        if (!text) {
            throw new HttpsError("internal", "Failed to generate text from Gemini.");
        }

        return { message: text.trim() };
    } catch (error) {
        console.error("Gemini API Error:", error);
        throw new HttpsError("internal", "Error calling Gemini API.");
    }
});

exports.processPaymentAssistant = onCall({ secrets: [geminiApiKey] }, async (request) => {
    // Check auth
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const { prompt } = request.data;
    if (!prompt) {
        throw new HttpsError("invalid-argument", "Missing prompt.");
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
        throw new HttpsError("failed-precondition", "Gemini API key is not configured.");
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-pro",
        generationConfig: { responseMimeType: "application/json" },
    });

    const instruction = `
You are an intelligent payment recording assistant. Extract the following entities from the natural language text and return them strictly in JSON format.

{
  "partyName": "The exact name of the customer or supplier (e.g., John Smith, Acme Corp)",
  "amount": The numeric value of the amount paid or received without currency symbols (e.g., 500.0),
  "paymentMethod": "One of these exact string values: 'cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other'"
}

If the payment method is not clearly specified, default to 'other'. Do not include extra text, just the raw JSON output.
Text: "${prompt}"
  `;

    try {
        const result = await model.generateContent(instruction);
        const response = await result.response;
        const text = response.text();

        if (!text) {
            throw new HttpsError("internal", "Failed to extract entities.");
        }

        try {
            return JSON.parse(text);
        } catch (e) {
            const cleanedText = text
                .replace(/```json/g, "")
                .replace(/```/g, "")
                .trim();
            return JSON.parse(cleanedText);
        }
    } catch (error) {
        console.error("Gemini API Error:", error);
        throw new HttpsError("internal", "Error calling Gemini API.");
    }
});
