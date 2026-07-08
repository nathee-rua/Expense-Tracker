import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_config.dart';
import '../services/api_service.dart';

class AISettingsScreen extends StatefulWidget {
  final String apiBaseUrl;

  const AISettingsScreen({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final ApiService _apiService = ApiService();
  
  // Persistent Settings State
  String _activeProviderId = 'gemini';
  String _activeModel = 'gemini-1.5-flash';
  final Map<String, String> _apiKeys = {};
  
  // Model management state
  final Map<String, List<String>> _providerModels = {};
  final Map<String, bool> _loadingModels = {};
  final Map<String, bool> _obscureKeys = {};
  
  bool _isSaving = false;
  String _connectionTestStatus = '';
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    // Initialize key obscuring map
    for (var p in AIConfig.providers) {
      _obscureKeys[p.id] = true;
      _providerModels[p.id] = List.from(p.defaultFreeModels);
    }
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeProviderId = prefs.getString('active_provider') ?? 'gemini';
      _activeModel = prefs.getString('active_model') ?? 'gemini-1.5-flash';
      
      for (var p in AIConfig.providers) {
        _apiKeys[p.id] = prefs.getString('key_${p.id}') ?? '';
      }
    });

    // Fetch models in real-time for the active provider
    _fetchRealTimeModels(_activeProviderId);
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_provider', _activeProviderId);
    await prefs.setString('active_model', _activeModel);
    
    for (var entry in _apiKeys.entries) {
      await prefs.setString('key_${entry.key}', entry.value);
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2ECC71),
          content: Text("AI settings saved successfully!"),
        ),
      );
    }
  }

  Future<void> _fetchRealTimeModels(String providerId) async {
    final key = _apiKeys[providerId] ?? '';
    // Skip checking if no key is entered (except for freellm which is public)
    if (key.isEmpty && providerId != 'freellm') return;

    setState(() {
      _loadingModels[providerId] = true;
    });

    final models = await _apiService.fetchModels(
      provider: providerId,
      apiKey: key,
      baseUrl: widget.apiBaseUrl,
    );

    if (mounted) {
      setState(() {
        _loadingModels[providerId] = false;
        if (models.isNotEmpty) {
          _providerModels[providerId] = models;
          // If the currently selected model is not in the new list, reset to first model
          if (providerId == _activeProviderId && !models.contains(_activeModel)) {
            _activeModel = models.first;
          }
        }
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestStatus = "Testing provider response...";
    });

    try {
      final key = _apiKeys[_activeProviderId] ?? '';
      final testResult = await _apiService.parseReceipt(
        data: "Test connection message. Respond with empty items list and valid JSON format.",
        isImage: false,
        baseUrl: widget.apiBaseUrl,
        provider: _activeProviderId,
        model: _activeModel,
        apiKey: key,
      );

      setState(() {
        _isTestingConnection = false;
        if (testResult['success'] == true) {
          _connectionTestStatus = "SUCCESS: Provider ${_activeProviderId.toUpperCase()} is connected and model '$_activeModel' successfully parsed mock text!";
        } else {
          _connectionTestStatus = "FAILED: ${testResult['error']}";
        }
      });
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestStatus = "FAILED: Network error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI Configuration Manager", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF2ECC71)),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Settings Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF8E2DE2).withOpacity(0.15), const Color(0xFF4A00E0).withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8E2DE2).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ACTIVE PARSER SETTING", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Text(
                      "${AIConfig.getProvider(_activeProviderId).name} • $_activeModel",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isTestingConnection ? null : _testConnection,
                          icon: const Icon(Icons.bolt, size: 16, color: Colors.amber),
                          label: const Text("Test Connection", style: TextStyle(fontSize: 12)),
                        ),
                        if (_isTestingConnection)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    if (_connectionTestStatus.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _connectionTestStatus,
                        style: TextStyle(
                          color: _connectionTestStatus.startsWith("SUCCESS") ? const Color(0xFF2ECC71) : const Color(0xFFFF5E62),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("MANAGE PROVIDERS & API KEYS", style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              
              // List of 10 providers
              ...AIConfig.providers.map((p) => _buildProviderCard(p)).toList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderInfo p) {
    final isActive = _activeProviderId == p.id;
    final key = _apiKeys[p.id] ?? '';
    final modelsList = _providerModels[p.id] ?? p.defaultFreeModels;
    final isLoadingModelsList = _loadingModels[p.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? const Color(0xFF8E2DE2).withOpacity(0.6) : Colors.white.withOpacity(0.04)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              p.name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white90,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF8E2DE2).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text("ACTIVE", style: TextStyle(color: Color(0xFF00C6FF), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(p.description, style: TextStyle(color: Colors.white30, fontSize: 10)),
        leading: Icon(
          p.supportsVision ? Icons.visibility : Icons.text_fields,
          color: isActive ? const Color(0xFF8E2DE2) : Colors.white24,
          size: 20,
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Key input
          if (p.id != 'freellm') ...[
            TextField(
              obscureText: _obscureKeys[p.id] ?? true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: "${p.name} API Key",
                labelStyle: const TextStyle(color: Colors.white50, fontSize: 12),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
                suffixIcon: IconButton(
                  icon: Icon(
                    (_obscureKeys[p.id] ?? true) ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureKeys[p.id] = !(_obscureKeys[p.id] ?? true);
                    });
                  },
                ),
              ),
              controller: TextEditingController(text: key)..selection = TextSelection.fromPosition(TextPosition(offset: key.length)),
              onChanged: (val) {
                _apiKeys[p.id] = val.trim();
              },
            ),
            const SizedBox(height: 12),
          ],
          
          // Model Selection Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selected Model", style: TextStyle(color: Colors.white60, fontSize: 12)),
              if (isLoadingModelsList)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white38, size: 16),
                  tooltip: "Fetch Real-Time Models",
                  onPressed: () => _fetchRealTimeModels(p.id),
                ),
            ],
          ),
          const SizedBox(height: 6),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E1E2C),
                value: modelsList.contains(isActive ? _activeModel : modelsList.first)
                    ? (isActive ? _activeModel : modelsList.first)
                    : modelsList.first,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: modelsList.map((m) {
                  return DropdownMenuItem<String>(
                    value: m,
                    child: Text(m, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newModel) {
                  if (newModel != null) {
                    setState(() {
                      _activeProviderId = p.id;
                      _activeModel = newModel;
                    });
                    _saveSettings();
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Activate Provider Button
          if (!isActive)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _activeProviderId = p.id;
                  // Set to first model in modelsList
                  _activeModel = modelsList.contains(_activeModel) ? _activeModel : modelsList.first;
                });
                _saveSettings();
              },
              child: const Text("Set as Active Provider", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
