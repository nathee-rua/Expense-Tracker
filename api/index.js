const express = require('express');
const dotenv = require('dotenv');
const axios = require('axios');
const cors = require('cors');

dotenv.config();
const app = express();

// Enable CORS for all origins so the Flutter app can access it
app.use(cors());
app.use(express.json({ limit: '50mb' }));

const SYSTEM_PROMPT = `You are a premium financial data parser. Extract financial data from the provided Thai bank slip, receipt, or text.
Return ONLY a valid JSON object. Do not include markdown blocks like \`\`\`json or any conversational text.

The JSON structure must be:
{
  "transaction_date": "YYYY-MM-DD",
  "transaction_time": "HH:MM",
  "amount": 0.00,
  "sender_name": "Name or null",
  "receiver_name": "Name or null",
  "bank_name": "Bank Name or null",
  "items": [],
  "category": "Auto-categorized category (e.g., Food, Travel, Utilities, Shopping, Entertainment)"
}`;

function cleanJsonString(str) {
  if (!str) return '';
  let cleaned = str.trim();

  // Strip markdown code blocks
  cleaned = cleaned.replace(/^```json\s*/i, '');
  cleaned = cleaned.replace(/^```\s*/, '');
  cleaned = cleaned.replace(/```\s*$/, '');
  cleaned = cleaned.trim();

  // Extract JSON object if it has surrounding text
  if (!cleaned.startsWith('{')) {
    const firstBrace = cleaned.indexOf('{');
    const lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }
  }

  return cleaned;
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: "alive",
    activeProvider: process.env.ACTIVE_PROVIDER || "gemini",
    configuredProviders: {
      gemini: !!process.env.GEMINI_API_KEY,
      openrouter: !!process.env.OPENROUTER_API_KEY,
      groq: !!process.env.GROQ_API_KEY
    }
  });
});

// Parse Receipt endpoint
app.post('/api/parse-receipt', async (req, res) => {
  const { data, isImage } = req.body;
  if (!data) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  const primaryProvider = process.env.ACTIVE_PROVIDER || 'gemini';
  const providersChain = [primaryProvider, 'gemini', 'openrouter', 'groq'];
  
  // Remove duplicates from the fallback chain
  const uniqueProviders = [...new Set(providersChain)];
  
  const errors = {};

  for (const provider of uniqueProviders) {
    try {
      let resultText = '';

      if (provider === 'gemini') {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) throw new Error("Gemini API key is not configured");

        const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
        const contents = [
          {
            parts: isImage 
              ? [
                  { text: SYSTEM_PROMPT },
                  { inlineData: { mimeType: "image/jpeg", data: data } }
                ]
              : [
                  { text: SYSTEM_PROMPT },
                  { text: data }
                ]
          }
        ];

        const response = await axios.post(url, { contents }, { timeout: 15000 });
        
        if (response.data && response.data.candidates && response.data.candidates[0].content.parts[0].text) {
          resultText = response.data.candidates[0].content.parts[0].text;
        } else {
          throw new Error("Invalid response format from Gemini API");
        }

      } else if (provider === 'openrouter') {
        const apiKey = process.env.OPENROUTER_API_KEY;
        if (!apiKey) throw new Error("OpenRouter API key is not configured");

        const url = "https://openrouter.ai/api/v1/chat/completions";
        const messages = isImage 
          ? [
              {
                role: "user",
                content: [
                  { type: "text", text: SYSTEM_PROMPT },
                  { type: "image_url", image_url: { url: `data:image/jpeg;base64,${data}` } }
                ]
              }
            ]
          : [
              { role: "system", content: SYSTEM_PROMPT },
              { role: "user", content: data }
            ];

        const response = await axios.post(
          url,
          { model: "google/gemini-flash-1.5", messages },
          { headers: { "Authorization": `Bearer ${apiKey}` }, timeout: 15000 }
        );

        if (response.data && response.data.choices && response.data.choices[0].message.content) {
          resultText = response.data.choices[0].message.content;
        } else {
          throw new Error("Invalid response format from OpenRouter API");
        }

      } else if (provider === 'groq') {
        const apiKey = process.env.GROQ_API_KEY;
        if (!apiKey) throw new Error("Groq API key is not configured");
        if (isImage) throw new Error("Groq text-only model does not support image parsing directly");

        const url = "https://api.groq.com/openai/v1/chat/completions";
        const response = await axios.post(
          url,
          {
            model: "llama-3.1-8b-instant",
            messages: [
              { role: "system", content: SYSTEM_PROMPT },
              { role: "user", content: data }
            ],
            response_format: { type: "json_object" }
          },
          { headers: { "Authorization": `Bearer ${apiKey}` }, timeout: 15000 }
        );

        if (response.data && response.data.choices && response.data.choices[0].message.content) {
          resultText = response.data.choices[0].message.content;
        } else {
          throw new Error("Invalid response format from Groq API");
        }
      }

      // If we got here, parse the JSON and return it
      const cleanedText = cleanJsonString(resultText);
      const parsedResult = JSON.parse(cleanedText);

      return res.json({
        success: true,
        provider: provider,
        data: parsedResult
      });

    } catch (err) {
      console.error(`Provider ${provider} failed:`, err.message);
      errors[provider] = err.message;
    }
  }

  // If we exhausted all options and they all failed
  return res.status(500).json({
    success: false,
    error: "All configured AI providers failed to parse the receipt data.",
    details: errors
  });
});

// For local testing
if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
