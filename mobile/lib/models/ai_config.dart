class ProviderInfo {
  final String id;
  final String name;
  final List<String> defaultFreeModels;
  final bool supportsVision;
  final String description;

  const ProviderInfo({
    required this.id,
    required this.name,
    required this.defaultFreeModels,
    required this.supportsVision,
    required this.description,
  });
}

class AIConfig {
  static const List<ProviderInfo> providers = [
    ProviderInfo(
      id: 'gemini',
      name: 'Google Gemini',
      defaultFreeModels: ['gemini-1.5-flash', 'gemini-1.5-pro'],
      supportsVision: true,
      description: 'Native Google Gemini API. Offers generous free tier requests.',
    ),
    ProviderInfo(
      id: 'openrouter',
      name: 'OpenRouter',
      defaultFreeModels: [
        'google/gemini-flash-1.5',
        'meta-llama/llama-3-8b-instruct:free',
        'openchat/openchat-7b:free',
        'qwen/qwen-2-7b-instruct:free',
        'microsoft/phi-3-medium-128k-instruct:free',
      ],
      supportsVision: true,
      description: 'Unified router. Includes free API models from various creators.',
    ),
    ProviderInfo(
      id: 'groq',
      name: 'Groq',
      defaultFreeModels: ['llama-3.1-8b-instant', 'llama-3.1-70b-versatile', 'mixtral-8x7b-32768'],
      supportsVision: false,
      description: 'Ultra-fast inference platform. Excellent for offline OCR text parsing.',
    ),
    ProviderInfo(
      id: 'xai',
      name: 'xAI (Grok)',
      defaultFreeModels: ['grok-beta'],
      supportsVision: true,
      description: 'xAI Grok service. High quality parsing and reasoning.',
    ),
    ProviderInfo(
      id: 'nvidia',
      name: 'NVIDIA NIM',
      defaultFreeModels: ['meta/llama3-8b-instruct', 'nvidia/neva-22b'],
      supportsVision: true,
      description: 'NVIDIA NIM catalog. High-performance models with free credits.',
    ),
    ProviderInfo(
      id: 'moonshot',
      name: 'MoonshotAI',
      defaultFreeModels: ['moonshot-v1-8k', 'moonshot-v1-32k'],
      supportsVision: false,
      description: 'Moonshot Kimi LLM. Highly specialized in structural text parsing.',
    ),
    ProviderInfo(
      id: 'freellm',
      name: 'freellm.net',
      defaultFreeModels: ['gpt-3.5-turbo', 'gpt-4', 'claude-instant-1'],
      supportsVision: true,
      description: 'Free wrapper access endpoint to OpenAI and Claude models.',
    ),
    ProviderInfo(
      id: 'ovh',
      name: 'OVHcloud AI',
      defaultFreeModels: ['meta-llama-3-8b-instruct', 'mixtral-8x7b-instruct'],
      supportsVision: false,
      description: 'European cloud provider hosting open-source model nodes.',
    ),
    ProviderInfo(
      id: 'modelscope',
      name: 'ModelScope',
      defaultFreeModels: ['qwen-turbo', 'qwen-plus', 'llama3-8b'],
      supportsVision: true,
      description: 'Alibaba ModelScope MaaS. Excellent Qwen Chinese/Thai support.',
    ),
    ProviderInfo(
      id: 'huggingface',
      name: 'Hugging Face',
      defaultFreeModels: [
        'meta-llama/Meta-Llama-3-8B-Instruct',
        'mistralai/Mistral-7B-Instruct-v0.2',
        'microsoft/Phi-3-mini-4k-instruct',
        'Qwen/Qwen2.5-7B-Instruct'
      ],
      supportsVision: false,
      description: 'Hugging Face Serverless Inference. Access to thousands of free models.',
    ),
  ];

  static ProviderInfo getProvider(String id) {
    return providers.firstWhere((p) => p.id == id, orElse: () => providers.first);
  }
}
