const express = require('express');
const dotenv = require('dotenv');
const axios = require('axios');
const cors = require('cors');

dotenv.config();
const app = express();

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

// Helper for OpenAI-compatible completions
async function callOpenAiCompatible(url, key, model, prompt, data, isImage, options = {}) {
  const headers = {
    "Authorization": `Bearer ${key}`,
    "Content-Type": "application/json"
  };

  // Modern LLMs prefer image parts or standard text
  let messages = [];
  if (isImage) {
    messages = [
      {
        role: "user",
        content: [
          { type: "text", text: prompt },
          { type: "image_url", image_url: { url: `data:image/jpeg;base64,${data}` } }
        ]
      }
    ];
  } else {
    messages = [
      { role: "system", content: prompt },
      { role: "user", content: data }
    ];
  }

  const payload = {
    model: model,
    messages: messages,
    temperature: 0.1
  };

  // Add json_object response format if requested and supported
  if (options.useJsonMode) {
    payload.response_format = { type: "json_object" };
  }

  const response = await axios.post(url, payload, { headers, timeout: 20000 });
  
  if (response.data && response.data.choices && response.data.choices[0].message.content) {
    return response.data.choices[0].message.content;
  }
  throw new Error("Invalid completion response from API");
}

// Endpoint to load real-time models from providers
app.get('/api/models', async (req, res) => {
  const provider = req.query.provider;
  const passedKey = req.query.apiKey;

  if (!provider) {
    return res.status(400).json({ success: false, error: "Missing provider parameter" });
  }

  const key = passedKey || process.env[`${provider.toUpperCase()}_API_KEY`];

  try {
    let models = [];

    switch (provider.toLowerCase()) {
      case 'gemini':
        // Get native models
        const geminiKey = key || process.env.GEMINI_API_KEY;
        if (!geminiKey) return res.json({ success: true, models: ['gemini-1.5-flash', 'gemini-1.5-pro'] });
        const geminiRes = await axios.get(`https://generativelanguage.googleapis.com/v1beta/models?key=${geminiKey}`, { timeout: 8000 });
        if (geminiRes.data && geminiRes.data.models) {
          models = geminiRes.data.models
            .map(m => m.name.replace('models/', ''))
            .filter(name => name.includes('gemini'));
        }
        break;

      case 'openrouter':
        const orRes = await axios.get('https://openrouter.ai/api/v1/models', { timeout: 8000 });
        if (orRes.data && orRes.data.data) {
          models = orRes.data.data.map(m => m.id);
        }
        break;

      case 'groq':
        if (!key) return res.json({ success: true, models: ['llama-3.1-8b-instant', 'llama-3.1-70b-versatile', 'llama3-70b-8192'] });
        const groqRes = await axios.get('https://api.groq.com/openai/v1/models', {
          headers: { "Authorization": `Bearer ${key}` },
          timeout: 8000
        });
        if (groqRes.data && groqRes.data.data) {
          models = groqRes.data.data.map(m => m.id);
        }
        break;

      case 'xai':
        if (!key) return res.json({ success: true, models: ['grok-beta'] });
        const xaiRes = await axios.get('https://api.x.ai/v1/models', {
          headers: { "Authorization": `Bearer ${key}` },
          timeout: 8000
        });
        if (xaiRes.data && xaiRes.data.models) {
          models = xaiRes.data.models.map(m => m.id);
        }
        break;

      case 'nvidia':
        if (!key) return res.json({ success: true, models: ['meta/llama3-8b-instruct', 'nvidia/neva-22b'] });
        const nvRes = await axios.get('https://integrate.api.nvidia.com/v1/models', {
          headers: { "Authorization": `Bearer ${key}` },
          timeout: 8000
        });
        if (nvRes.data && nvRes.data.data) {
          models = nvRes.data.data.map(m => m.id);
        }
        break;

      case 'moonshot':
        if (!key) return res.json({ success: true, models: ['moonshot-v1-8k', 'moonshot-v1-32k'] });
        const msRes = await axios.get('https://api.moonshot.ai/v1/models', {
          headers: { "Authorization": `Bearer ${key}` },
          timeout: 8000
        });
        if (msRes.data && msRes.data.data) {
          models = msRes.data.data.map(m => m.id);
        }
        break;

      case 'huggingface':
        // Predefined list of popular free LLMs since dynamic listing is too large
        models = [
          'meta-llama/Meta-Llama-3-8B-Instruct',
          'mistralai/Mistral-7B-Instruct-v0.2',
          'microsoft/Phi-3-mini-4k-instruct',
          'Qwen/Qwen2.5-7B-Instruct'
        ];
        break;

      case 'modelscope':
        models = [
          'qwen-turbo',
          'qwen-plus',
          'llama3-8b'
        ];
        break;

      case 'freellm':
        models = [
          'gpt-3.5-turbo',
          'gpt-4',
          'claude-instant-1'
        ];
        break;

      case 'ovh':
        models = [
          'meta-llama-3-8b-instruct',
          'mixtral-8x7b-instruct'
        ];
        break;

      default:
        models = [];
    }

    return res.json({ success: true, models });

  } catch (err) {
    console.error(`Failed to load models for ${provider}:`, err.message);
    // Return empty list on failure instead of error, so front-end defaults are used
    return res.json({ success: true, models: [], error: err.message });
  }
});

// Dynamic AI parsing endpoint
app.post('/api/parse-receipt', async (req, res) => {
  const { data, isImage, fileType, provider, model, apiKey } = req.body;
  if (!data) {
    return res.status(400).json({ success: false, error: "Missing data" });
  }

  // Determine active provider, model, and key
  const activeProvider = (provider || process.env.ACTIVE_PROVIDER || 'gemini').toLowerCase();

  // Validate PDF provider restriction
  if (fileType === 'pdf' && activeProvider !== 'gemini') {
    return res.status(400).json({
      success: false,
      error: "PDF parsing is only supported by Google Gemini. Please switch your active provider to Google Gemini in settings."
    });
  }
  
  // Resolve key (passed in body takes precedence over env variables)
  const resolvedKey = apiKey || process.env[`${activeProvider.toUpperCase()}_API_KEY`];
  if (!resolvedKey && activeProvider !== 'freellm') {
    return res.status(400).json({
      success: false,
      error: `API key for provider '${activeProvider}' is not configured. Please add it in settings.`
    });
  }

  try {
    let resultText = '';

    if (activeProvider === 'gemini') {
      const activeModel = model || 'gemini-1.5-flash';
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${activeModel}:generateContent?key=${resolvedKey}`;
      
      let part;
      if (fileType === 'pdf') {
        part = { inlineData: { mimeType: "application/pdf", data: data } };
      } else if (isImage) {
        part = { inlineData: { mimeType: "image/jpeg", data: data } };
      } else {
        part = { text: data };
      }

      const contents = [
        {
          parts: [
            { text: SYSTEM_PROMPT },
            part
          ]
        }
      ];

      const response = await axios.post(url, { contents }, { timeout: 20000 });
      if (response.data && response.data.candidates && response.data.candidates[0].content.parts[0].text) {
        resultText = response.data.candidates[0].content.parts[0].text;
      } else {
        throw new Error("Invalid response format from Gemini API");
      }

    } else if (activeProvider === 'openrouter') {
      const activeModel = model || 'google/gemini-flash-1.5';
      resultText = await callOpenAiCompatible(
        "https://openrouter.ai/api/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );

    } else if (activeProvider === 'groq') {
      const activeModel = model || 'llama-3.1-8b-instant';
      if (isImage) throw new Error("Groq llama models do not support vision. Please extract text locally first.");
      resultText = await callOpenAiCompatible(
        "https://api.groq.com/openai/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        false,
        { useJsonMode: true }
      );

    } else if (activeProvider === 'xai') {
      const activeModel = model || 'grok-beta';
      resultText = await callOpenAiCompatible(
        "https://api.x.ai/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );

    } else if (activeProvider === 'nvidia') {
      const activeModel = model || 'meta/llama3-8b-instruct';
      resultText = await callOpenAiCompatible(
        "https://integrate.api.nvidia.com/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );

    } else if (activeProvider === 'moonshot') {
      const activeModel = model || 'moonshot-v1-8k';
      if (isImage) throw new Error("Moonshot models are text-only. Please use local OCR text instead.");
      resultText = await callOpenAiCompatible(
        "https://api.moonshot.ai/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        false
      );

    } else if (activeProvider === 'freellm') {
      const activeModel = model || 'gpt-3.5-turbo';
      // FreeLLM API endpoint
      resultText = await callOpenAiCompatible(
        "https://api.freellm.net/v1/chat/completions",
        resolvedKey || "free_key",
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );

    } else if (activeProvider === 'ovh') {
      const activeModel = model || 'meta-llama-3-8b-instruct';
      resultText = await callOpenAiCompatible(
        "https://api.ai.ovh.net/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );

    } else if (activeProvider === 'modelscope') {
      const activeModel = model || 'qwen-turbo';
      resultText = await callOpenAiCompatible(
        "https://api.modelscope.cn/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );

    } else if (activeProvider === 'huggingface') {
      const activeModel = model || 'meta-llama/Meta-Llama-3-8B-Instruct';
      // Hugging Face standard inference URL supports openai completions layout
      resultText = await callOpenAiCompatible(
        "https://api-inference.huggingface.co/v1/chat/completions",
        resolvedKey,
        activeModel,
        SYSTEM_PROMPT,
        data,
        isImage
      );
    } else {
      throw new Error(`Unsupported provider: ${activeProvider}`);
    }

    // Parse and clean JSON
    const cleanedText = cleanJsonString(resultText);
    const parsedResult = JSON.parse(cleanedText);

    return res.json({
      success: true,
      provider: activeProvider,
      model: model,
      data: parsedResult
    });

  } catch (err) {
    console.error(`AI parsing failed for ${activeProvider}:`, err.message);
    return res.status(500).json({
      success: false,
      error: `AI parsing failed: ${err.message}`
    });
  }
});

// For local testing
if (require.main === module) {
  const path = require('path');
  app.use(express.static(path.join(__dirname, '..')));
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
