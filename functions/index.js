const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");

// Initialize Firebase Admin
initializeApp();

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

exports.rapidFinancialEntry = onCall({ secrets: [geminiApiKey] }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const { prompt } = request.data;
    if (!prompt) {
        throw new HttpsError("invalid-argument", "Missing prompt.");
    }

    const apiKey = geminiApiKey.value();
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-pro",
        generationConfig: { responseMimeType: "application/json" },
    });

    const instruction = `
You are a Rapid Financial Entry Agent. Your job is to extract transaction details from the user's prompt.
Assume the input contains a full transaction.

Return strictly in JSON format:
{
  "type": "sale" | "purchase" | "payment",
  "partyName": "extracted name of the person or business",
  "amount": numeric_value,
  "notes": "brief summary",
  "invoiceNumber": "if mentioned, else null",
  "date": "ISO date if mentioned, else null",
  "paymentMethod": "if it's a payment, one of: 'cash', 'bank_transfer', 'cheque', 'upi', 'card', 'other'. Else null"
}

Examples:
- "50000 Canopas" -> {"type": "payment", "partyName": "Canopas", "amount": 50000, ...}
- "Purchase 10k from New Vendor" -> {"type": "purchase", "partyName": "New Vendor", "amount": 10000, ...}
- "Sold items for 500 to ABC" -> {"type": "sale", "partyName": "ABC", "amount": 500, ...}

Text: "${prompt}"
  `;

    try {
        const result = await model.generateContent(instruction);
        const response = await result.response;
        const text = response.text();
        return JSON.parse(text);
    } catch (error) {
        console.error("Gemini API Error:", error);
        throw new HttpsError("internal", "Error calling Gemini API.");
    }
});

exports.processTransactionAssistant = onCall({ secrets: [geminiApiKey] }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const { prompt, type } = request.data; // type: 'sales' or 'purchase'
    if (!prompt || !type) {
        throw new HttpsError("invalid-argument", "Missing prompt or type.");
    }

    const apiKey = geminiApiKey.value();
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-pro",
        generationConfig: { responseMimeType: "application/json" },
    });

    const instruction = `
You are an intelligent business assistant. Extract transaction details for a ${type} record from the text.
Return strictly in JSON format:
{
  "totalAmount": numeric_value,
  "notes": "brief summary of items/transaction",
  "invoiceNumber": "if mentioned, else null",
  "date": "ISO date for invoiceDate if mentioned, else null"
}

Text: "${prompt}"
  `;

    try {
        const result = await model.generateContent(instruction);
        const response = await result.response;
        const text = response.text();
        return JSON.parse(text);
    } catch (error) {
        console.error("Gemini API Error:", error);
        throw new HttpsError("internal", "Error calling Gemini API.");
    }
});

exports.analyzeCashflow = onCall({ secrets: [geminiApiKey] }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
    }

    const { getFirestore } = require("firebase-admin/firestore");
    const db = getFirestore();
    const userId = request.auth.uid;

    try {
        const invoicesSnapshot = await db.collection("users").doc(userId).collection("invoices").get();
        const invoices = invoicesSnapshot.docs.map(doc => doc.data());

        const today = new Date();
        const next30Days = new Date();
        next30Days.setDate(today.getDate() + 30);

        let totalUpcomingReceivables = 0;
        let totalUpcomingPayables = 0;
        const dailyProjections = {};

        // Pattern detection: High Risk
        const partyStatusHistory = {};

        invoices.forEach(inv => {
            const dueDate = inv.dueDate ? inv.dueDate.toDate() : null;
            const amount = inv.outstandingAmount || 0;
            const type = inv.invoiceType;

            if (dueDate && dueDate >= today && dueDate <= next30Days) {
                const dateKey = dueDate.toISOString().split("T")[0];
                if (!dailyProjections[dateKey]) {
                    dailyProjections[dateKey] = { receivables: 0, payables: 0 };
                }

                if (type === "sales") {
                    totalUpcomingReceivables += amount;
                    dailyProjections[dateKey].receivables += amount;
                } else {
                    totalUpcomingPayables += amount;
                    dailyProjections[dateKey].payables += amount;
                }
            }

            const partyId = inv.partyId;
            if (partyId) {
                if (!partyStatusHistory[partyId]) {
                    partyStatusHistory[partyId] = { name: inv.partyName, total: 0, partial: 0 };
                }
                partyStatusHistory[partyId].total++;
                if (inv.paymentStatus === "partial") {
                    partyStatusHistory[partyId].partial++;
                }
            }
        });

        const highRiskParties = Object.keys(partyStatusHistory)
            .filter(pid => {
                const stats = partyStatusHistory[pid];
                return stats.total >= 3 && (stats.partial / stats.total) >= 0.5;
            })
            .map(pid => ({
                partyId: pid,
                partyName: partyStatusHistory[pid].name,
                riskLevel: "High Risk",
                reason: "Consistent partial payment history",
            }));

        const coveragePercent = totalUpcomingPayables > 0
            ? Math.round((totalUpcomingReceivables / totalUpcomingPayables) * 100)
            : 100;

        return {
            totalUpcomingReceivables,
            totalUpcomingPayables,
            coveragePercent,
            dailyProjections,
            highRiskParties,
            summaryMessage: `You are expected to receive ₹${totalUpcomingReceivables.toLocaleString("en-IN")} by the end of the month, which covers ${coveragePercent}% of your upcoming payables (₹${totalUpcomingPayables.toLocaleString("en-IN")}).`
        };
    } catch (error) {
        console.error("Cashflow Analysis Error:", error);
        throw new HttpsError("internal", "Error analyzing cashflow data.");
    }
});
