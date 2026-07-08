/* ==========================================
   PREMIUM EXPENSE TRACKER - MAIN CORE SCRIPT
   ========================================== */

// --- 1. AI Configuration Definition (Aligns with mobile AIConfig) ---
const AI_PROVIDERS = [
    {
        id: 'gemini',
        name: 'Google Gemini',
        defaultFreeModels: ['gemini-1.5-flash', 'gemini-1.5-pro'],
        supportsVision: true,
        description: 'Native Google Gemini API. มีโควตาฟรีให้ใช้งานค่อนข้างสูง'
    },
    {
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
        description: 'บริการรวม API สองฝั่ง รองรับโมเดลฟรีคุณภาพสูง'
    },
    {
        id: 'groq',
        name: 'Groq',
        defaultFreeModels: ['llama-3.1-8b-instant', 'llama-3.1-70b-versatile', 'mixtral-8x7b-32768'],
        supportsVision: false,
        description: 'แพลตฟอร์มประมวลผลด่วนพิเศษ เหมาะสำหรับถอดข้อความ OCR มาวิเคราะห์ต่อ'
    },
    {
        id: 'xai',
        name: 'xAI (Grok)',
        defaultFreeModels: ['grok-beta'],
        supportsVision: true,
        description: 'บริการ xAI Grok วิเคราะห์และถอดแยกสลิปที่ซับซ้อนได้เป็นอย่างดี'
    },
    {
        id: 'nvidia',
        name: 'NVIDIA NIM',
        defaultFreeModels: ['meta/llama3-8b-instruct', 'nvidia/neva-22b'],
        supportsVision: true,
        description: 'NVIDIA NIM Catalog มีเครดิตฟรีให้ใช้งานเมื่อสมัครครั้งแรก'
    },
    {
        id: 'moonshot',
        name: 'MoonshotAI',
        defaultFreeModels: ['moonshot-v1-8k', 'moonshot-v1-32k'],
        supportsVision: false,
        description: 'Moonshot Kimi LLM เด่นด้านวิเคราะห์โครงสร้างข้อมูลจากตัวอักษร'
    },
    {
        id: 'freellm',
        name: 'freellm.net',
        defaultFreeModels: ['gpt-3.5-turbo', 'gpt-4', 'claude-instant-1'],
        supportsVision: true,
        description: 'เกตเวย์ฟรีสำหรับการเชื่อมต่อกับโมเดล OpenAI และ Claude'
    },
    {
        id: 'ovh',
        name: 'OVHcloud AI',
        defaultFreeModels: ['meta-llama-3-8b-instruct', 'mixtral-8x7b-instruct'],
        supportsVision: false,
        description: 'คลาวด์ยุโรปที่โฮสต์ Node แบบ Open-source'
    },
    {
        id: 'modelscope',
        name: 'ModelScope',
        defaultFreeModels: ['qwen-turbo', 'qwen-plus', 'llama3-8b'],
        supportsVision: true,
        description: 'Alibaba MaaS รองรับ Qwen ภาษาไทยได้สมบูรณ์'
    },
    {
        id: 'huggingface',
        name: 'Hugging Face',
        defaultFreeModels: [
            'meta-llama/Meta-Llama-3-8B-Instruct',
            'mistralai/Mistral-7B-Instruct-v0.2',
            'microsoft/Phi-3-mini-4k-instruct',
            'Qwen/Qwen2.5-7B-Instruct'
        ],
        supportsVision: false,
        description: 'Serverless Inference แบบฟรี เข้าถึงโมเดลยอดนิยมได้หลากหลาย'
    }
];

// --- 2. Application State ---
let state = {
    budget: 15000.00,
    apiBaseUrl: '',
    activeProvider: 'gemini',
    activeModel: 'gemini-1.5-flash',
    categories: ['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'],
    apiKeys: {},
    expenses: []
};

// Category translation mapping (Aligns with mobile)
const CATEGORY_TRANSLATIONS = {
    'food': 'อาหาร',
    'travel': 'การเดินทาง',
    'utilities': 'ค่าสาธารณูปโภค',
    'shopping': 'ช้อปปิ้ง',
    'entertainment': 'ความบันเทิง',
    'other': 'อื่นๆ'
};

function getCategoryDisplayName(cat) {
    const lower = cat.toLowerCase().trim();
    return CATEGORY_TRANSLATIONS[lower] || cat;
}

// Chart Instances
let categoryChartInstance = null;
let trendChartInstance = null;

// --- 3. DOM Elements ---
const el = {
    healthDot: document.querySelector('#health-status .status-dot'),
    healthText: document.querySelector('#health-status .status-text'),
    healthStatus: document.getElementById('health-status'),
    openSettingsBtn: document.getElementById('open-settings-btn'),
    
    // Bento Cards
    totalSpentVal: document.getElementById('total-spent-val'),
    budgetProgressFill: document.getElementById('budget-progress-fill'),
    budgetPercentageText: document.getElementById('budget-percentage-text'),
    remainingBudgetVal: document.getElementById('remaining-budget-val'),
    totalBudgetText: document.getElementById('total-budget-text'),
    dailyAverageVal: document.getElementById('daily-average-val'),
    projectedSpentVal: document.getElementById('projected-spent-val'),
    forecastWarning: document.getElementById('forecast-warning'),
    activeProviderName: document.getElementById('active-provider-name'),
    activeModelName: document.getElementById('active-model-name'),
    
    // Actions
    scanReceiptBtn: document.getElementById('scan-receipt-btn'),
    receiptFileInput: document.getElementById('receipt-file-input'),
    addManualBtn: document.getElementById('add-manual-btn'),
    
    // List & Filters
    searchInput: document.getElementById('search-input'),
    categoryFilter: document.getElementById('category-filter'),
    expenseListContainer: document.getElementById('expense-list-container'),
    
    // Settings Modal
    settingsModal: document.getElementById('settings-modal'),
    closeSettingsModal: document.getElementById('close-settings-modal'),
    settingsApiUrl: document.getElementById('settings-api-url'),
    settingsActiveProvider: document.getElementById('settings-active-provider'),
    settingsActiveModel: document.getElementById('settings-active-model'),
    modelLoader: document.getElementById('model-loader'),
    apiKeysAccordion: document.getElementById('api-keys-accordion'),
    testConnectionBtn: document.getElementById('test-connection-btn'),
    testResultBox: document.getElementById('test-result-box'),
    settingsBudget: document.getElementById('settings-budget'),
    newCategoryInput: document.getElementById('new-category-input'),
    addCategoryBtn: document.getElementById('add-category-btn'),
    categoryTagsContainer: document.getElementById('category-tags-container'),
    exportDataBtn: document.getElementById('export-data-btn'),
    importDataTrigger: document.getElementById('import-data-trigger'),
    importDataFile: document.getElementById('import-data-file'),
    cancelSettingsBtn: document.getElementById('cancel-settings-btn'),
    saveSettingsBtn: document.getElementById('save-settings-btn'),
    
    // Expense Modal
    expenseModal: document.getElementById('expense-modal'),
    closeExpenseModal: document.getElementById('close-expense-modal'),
    expenseModalTitle: document.getElementById('expense-modal-title'),
    expenseForm: document.getElementById('expense-form'),
    formExpenseId: document.getElementById('form-expense-id'),
    formDate: document.getElementById('form-date'),
    formTime: document.getElementById('form-time'),
    formAmount: document.getElementById('form-amount'),
    formReceiver: document.getElementById('form-receiver'),
    formCategory: document.getElementById('form-category'),
    formItemsContainer: document.getElementById('form-items-container'),
    addItemRowTrigger: document.getElementById('add-item-row-trigger'),
    formBank: document.getElementById('form-bank'),
    formRawOcr: document.getElementById('form-raw-ocr'),
    cancelExpenseBtn: document.getElementById('cancel-expense-btn'),
    saveExpenseBtn: document.getElementById('save-expense-btn'),
    
    // AI Loading
    aiLoadingOverlay: document.getElementById('ai-loading-overlay'),
    loadingStepText: document.getElementById('loading-step-text'),
    
    // Quick Budget Modal
    editBudgetTrigger: document.getElementById('edit-budget-trigger'),
    budgetQuickModal: document.getElementById('budget-quick-modal'),
    closeBudgetModal: document.getElementById('close-budget-modal'),
    quickBudgetInput: document.getElementById('quick-budget-input'),
    cancelBudgetBtn: document.getElementById('cancel-budget-btn'),
    saveBudgetBtn: document.getElementById('save-budget-btn'),
};

// --- 4. Initialization & LocalStorage Loader ---
function init() {
    // 4.1 Load configurations from localStorage
    state.budget = parseFloat(localStorage.getItem('total_budget')) || 15000.00;
    
    // If running from file protocol (opened locally), default backend to port 3000
    // Otherwise, default to relative origin (Vercel automatic same-origin resolution)
    const defaultApiUrl = window.location.protocol === 'file:' ? 'http://localhost:3000' : window.location.origin;
    state.apiBaseUrl = localStorage.getItem('api_base_url') || defaultApiUrl;
    
    state.activeProvider = localStorage.getItem('active_provider') || 'gemini';
    state.activeModel = localStorage.getItem('active_model') || 'gemini-1.5-flash';
    
    // Load categories
    const savedCategories = localStorage.getItem('saved_categories');
    if (savedCategories) {
        state.categories = JSON.parse(savedCategories);
    }
    
    // Load API Keys
    AI_PROVIDERS.forEach(p => {
        state.apiKeys[p.id] = localStorage.getItem(`key_${p.id}`) || '';
    });
    
    // Load Expenses
    const savedExpenses = localStorage.getItem('saved_expenses');
    if (savedExpenses) {
        try {
            state.expenses = JSON.parse(savedExpenses);
        } catch (e) {
            console.error("Error parsing saved expenses:", e);
            state.expenses = [];
        }
    } else {
        loadMockData();
    }
    
    // 4.2 Populate dropdown values and forms
    populateDropdowns();
    renderApiKeysAccordion();
    
    // 4.3 Add Event Listeners
    setupEventListeners();
    
    // 4.4 Render charts and recalculate dashboard numbers
    updateDashboard();
    
    // 4.5 Execute health check to backend API
    checkBackendHealth();
}

function loadMockData() {
    const today = new Date();
    const day = (d) => {
        const date = new Date(today);
        date.setDate(today.getDate() - d);
        return date.toISOString().split('T')[0];
    };
    
    state.expenses = [
        {
            id: "mock-web-1",
            transaction_date: day(1),
            transaction_time: "12:30",
            amount: 350.00,
            receiver_name: "ส้มตำแซ่บแซ่บ (Somtum Sab Zaap)",
            category: "Food",
            items: [{ name: "ส้มตำและไก่ย่าง (Somtum & Chicken)", price: 350.00, quantity: 1 }],
            bank_name: "กสิกรไทย (K-Plus)",
            rawOcrText: "K-Plus Transfer Successful\nDate: 2026-07-07 Time: 12:30\nTo: Somtum Sab Zaap\nAmount: 350.00 THB",
            parsedProvider: "gemini (mock)"
        },
        {
            id: "mock-web-2",
            transaction_date: day(2),
            transaction_time: "08:15",
            amount: 120.00,
            receiver_name: "รถไฟฟ้า BTS Skytrain",
            category: "Travel",
            items: [{ name: "บัตรเดินทางเที่ยวเดียว (Single Journey)", price: 120.00, quantity: 1 }],
            bank_name: "PromptPay",
            rawOcrText: "PromptPay QR Payment\nRef: BTS Skytrain\nAmount: 120.00 Baht\nSuccess",
            parsedProvider: "openrouter (mock)"
        },
        {
            id: "mock-web-3",
            transaction_date: day(3),
            transaction_time: "18:45",
            amount: 1450.00,
            receiver_name: "การไฟฟ้านครหลวง (MEA)",
            category: "Utilities",
            items: [{ name: "ค่าไฟเดือนมิถุนายน (Electricity bill)", price: 1450.00, quantity: 1 }],
            bank_name: "ไทยพาณิชย์ (SCB Easy)",
            rawOcrText: "SCB Easy\nPayment to: Metropolitan Electricity Authority\nAmount: 1,450.00 THB\nTransaction completed.",
            parsedProvider: "groq (mock)"
        },
        {
            id: "mock-web-4",
            transaction_date: day(4),
            transaction_time: "15:20",
            amount: 890.00,
            receiver_name: "Uniqlo Siam Paragon",
            category: "Shopping",
            items: [{ name: "เสื้อเชิ้ตพรีเมียมลินิน (Premium Linen Shirt)", price: 890.00, quantity: 1 }],
            bank_name: "กรุงไทย (Krungthai NEXT)",
            rawOcrText: "Krungthai NEXT\nTransaction: Transfer Success\nTo: UNIQLO THAILAND\nAmount: 890.00 THB",
            parsedProvider: "gemini (mock)"
        }
    ];
    saveExpenses();
}

function saveExpenses() {
    localStorage.setItem('saved_expenses', JSON.stringify(state.expenses));
}

// --- 5. UI Helpers (Form Populators & Grid Recalculations) ---
function populateDropdowns() {
    // 5.1 Fill category filters
    el.categoryFilter.innerHTML = '<option value="all">ทุกหมวดหมู่</option>';
    state.categories.forEach(cat => {
        el.categoryFilter.innerHTML += `<option value="${cat}">${getCategoryDisplayName(cat)}</option>`;
    });
    
    // 5.2 Fill form category options
    el.formCategory.innerHTML = '';
    state.categories.forEach(cat => {
        el.formCategory.innerHTML += `<option value="${cat}">${getCategoryDisplayName(cat)}</option>`;
    });
    
    // 5.3 Fill settings provider dropdown
    el.settingsActiveProvider.innerHTML = '';
    AI_PROVIDERS.forEach(p => {
        const isSelected = p.id === state.activeProvider ? 'selected' : '';
        el.settingsActiveProvider.innerHTML += `<option value="${p.id}" ${isSelected}>${p.name}</option>`;
    });
}

function renderApiKeysAccordion() {
    el.apiKeysAccordion.innerHTML = '';
    
    AI_PROVIDERS.forEach(p => {
        const isActive = p.id === state.activeProvider ? 'active' : '';
        const savedKey = state.apiKeys[p.id] || '';
        
        const accordionItemHtml = `
            <div class="provider-accordion-item ${isActive}" data-provider-id="${p.id}">
                <div class="provider-accordion-header">
                    <span>${p.name}</span>
                    <i class="fa-solid fa-chevron-down chevron"></i>
                </div>
                <div class="provider-accordion-body">
                    <p class="form-help-text" style="margin-bottom: 10px;">${p.description}</p>
                    <div class="form-group" style="margin-bottom: 0;">
                        <label>API Key:</label>
                        <div class="key-input-wrapper">
                            <input type="password" class="provider-key-input" data-provider-id="${p.id}" value="${savedKey}" placeholder="ใส่คีย์สำหรับ ${p.name}...">
                            <button type="button" class="toggle-key-visibility">
                                <i class="fa-solid fa-eye-slash"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        el.apiKeysAccordion.innerHTML += accordionItemHtml;
    });
    
    // Setup Accordion headers click handlers
    document.querySelectorAll('.provider-accordion-header').forEach(header => {
        header.addEventListener('click', () => {
            const item = header.parentElement;
            const wasActive = item.classList.contains('active');
            
            // Collapse all
            document.querySelectorAll('.provider-accordion-item').forEach(i => i.classList.remove('active'));
            
            // Expand clicked if it wasn't active
            if (!wasActive) {
                item.classList.add('active');
            }
        });
    });
    
    // Setup visibility toggle handlers
    document.querySelectorAll('.toggle-key-visibility').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const input = btn.previousElementSibling;
            const icon = btn.querySelector('i');
            
            if (input.type === 'password') {
                input.type = 'text';
                icon.className = 'fa-solid fa-eye';
            } else {
                input.type = 'password';
                icon.className = 'fa-solid fa-eye-slash';
            }
        });
    });
}

function updateDashboard() {
    // 6.1 Total Spent Calculation
    const totalSpent = state.expenses.reduce((sum, e) => sum + parseFloat(e.amount || 0), 0);
    el.totalSpentVal.innerText = `฿${totalSpent.toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    
    // 6.2 Budget percentage progress
    const pct = Math.min((totalSpent / state.budget) * 100, 100);
    el.budgetProgressFill.style.width = `${pct}%`;
    el.budgetPercentageText.innerText = `ใช้ไปแล้ว ${pct.toFixed(0)}% ของงบประมาณ`;
    
    if (pct >= 90) {
        el.budgetProgressFill.style.background = 'linear-gradient(90deg, var(--accent-red), #E74C3C)';
    } else if (pct >= 70) {
        el.budgetProgressFill.style.background = 'linear-gradient(90deg, var(--accent-orange), #F39C12)';
    } else {
        el.budgetProgressFill.style.background = 'linear-gradient(90deg, var(--accent-purple), var(--accent-blue))';
    }
    
    // 6.3 Remaining Budget
    const remaining = state.budget - totalSpent;
    el.remainingBudgetVal.innerText = `฿${remaining.toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    if (remaining < 0) {
        el.remainingBudgetVal.className = 'card-value text-red';
    } else {
        el.remainingBudgetVal.className = 'card-value text-green';
    }
    el.totalBudgetText.innerText = `งบประมาณทั้งหมด: ฿${state.budget.toLocaleString('th-TH', { minimumFractionDigits: 2 })}`;
    
    // 6.4 Forecast & Daily Averages
    const today = new Date();
    const currentMonth = today.getMonth();
    const currentYear = today.getFullYear();
    const elapsedDays = today.getDate();
    
    const monthlyExpenses = state.expenses.filter(e => {
        const d = new Date(e.transaction_date);
        return d.getMonth() === currentMonth && d.getFullYear() === currentYear;
    });
    
    const monthSpent = monthlyExpenses.reduce((sum, e) => sum + parseFloat(e.amount || 0), 0);
    const dailyAvg = monthSpent / (elapsedDays > 0 ? elapsedDays : 1);
    el.dailyAverageVal.innerText = `฿${dailyAvg.toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    
    const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
    const projectedSpent = dailyAvg * daysInMonth;
    el.projectedSpentVal.innerText = `฿${projectedSpent.toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    
    if (projectedSpent > state.budget) {
        el.forecastWarning.innerText = `⚠️ คาดการณ์ว่าการใช้จ่ายจะเกินงบประมาณ ฿${(projectedSpent - state.budget).toFixed(0)} บาท!`;
        el.forecastWarning.style.display = 'block';
    } else {
        el.forecastWarning.innerText = '';
        el.forecastWarning.style.display = 'none';
    }
    
    // 6.5 AI Card Details
    const currentProvInfo = AI_PROVIDERS.find(p => p.id === state.activeProvider);
    el.activeProviderName.innerText = currentProvInfo ? currentProvInfo.name : state.activeProvider;
    el.activeModelName.innerText = state.activeModel;
    
    // 6.6 Refresh Transaction List and Charts
    renderExpenseList();
    renderCharts();
}

// --- 6. Charts Renderer ---
function renderCharts() {
    // 7.1 Aggregate Category Expenses
    const categoriesMap = {};
    state.categories.forEach(c => categoriesMap[c] = 0);
    
    state.expenses.forEach(e => {
        // Fallback for custom categories not matched in default list
        const catName = state.categories.find(c => c.toLowerCase().trim() === e.category.toLowerCase().trim()) || 'Other';
        categoriesMap[catName] += parseFloat(e.amount || 0);
    });
    
    const categoryLabels = Object.keys(categoriesMap).map(c => getCategoryDisplayName(c));
    const categoryData = Object.values(categoriesMap);
    
    // Colors mapping to design system
    const baseColors = [
        '#e74c3c', // Food (Red)
        '#3498db', // Travel (Blue)
        '#f1c40f', // Utilities (Yellow)
        '#9b59b6', // Shopping (Purple)
        '#e67e22', // Entertainment (Orange)
        '#95a5a6', // Other (Grey)
        '#2ecc71', // Custom (Green)
        '#1abc9c', // Custom (Cyan)
        '#e84393'  // Custom (Pink)
    ];
    
    // 7.2 Donut Category Chart
    if (categoryChartInstance) categoryChartInstance.destroy();
    
    const ctxCategory = document.getElementById('categoryChart').getContext('2d');
    categoryChartInstance = new Chart(ctxCategory, {
        type: 'doughnut',
        data: {
            labels: categoryLabels,
            datasets: [{
                data: categoryData,
                backgroundColor: baseColors.slice(0, categoryLabels.length),
                borderColor: '#12121A',
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        color: '#F0F0F7',
                        font: { family: 'Kanit', size: 11 }
                    }
                }
            },
            cutout: '65%'
        }
    });
    
    // 7.3 Daily Spending Trend Chart (Last 15 days)
    const trendMap = {};
    const today = new Date();
    
    for (let i = 14; i >= 0; i--) {
        const tempDate = new Date(today);
        tempDate.setDate(today.getDate() - i);
        const dateStr = tempDate.toISOString().split('T')[0];
        trendMap[dateStr] = 0;
    }
    
    state.expenses.forEach(e => {
        if (trendMap[e.transaction_date] !== undefined) {
            trendMap[e.transaction_date] += parseFloat(e.amount || 0);
        }
    });
    
    const trendLabels = Object.keys(trendMap).map(dateStr => {
        const parts = dateStr.split('-');
        return `${parts[2]}/${parts[1]}`;
    });
    const trendData = Object.values(trendMap);
    
    if (trendChartInstance) trendChartInstance.destroy();
    
    const ctxTrend = document.getElementById('trendChart').getContext('2d');
    trendChartInstance = new Chart(ctxTrend, {
        type: 'line',
        data: {
            labels: trendLabels,
            datasets: [{
                label: 'ยอดใช้จ่ายรายวัน (บาท)',
                data: trendData,
                borderColor: '#9b59b6',
                backgroundColor: 'rgba(155, 89, 182, 0.15)',
                borderWidth: 3,
                fill: true,
                tension: 0.35,
                pointBackgroundColor: '#3498db',
                pointBorderColor: '#FFFFFF',
                pointRadius: 4,
                pointHoverRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: {
                    grid: { color: 'rgba(255, 255, 255, 0.03)' },
                    ticks: { color: '#A0A0B5', font: { family: 'Outfit', size: 10 } }
                },
                y: {
                    grid: { color: 'rgba(255, 255, 255, 0.03)' },
                    ticks: { color: '#A0A0B5', font: { family: 'Outfit', size: 10 } }
                }
            }
        }
    });
}

// --- 7. Expense List Renderer ---
function renderExpenseList() {
    const query = el.searchInput.value.toLowerCase().trim();
    const filterCat = el.categoryFilter.value;
    
    // Sort transactions latest first
    const sorted = [...state.expenses].sort((a, b) => {
        const dateA = new Date(`${a.transaction_date}T${a.transaction_time || '00:00'}`);
        const dateB = new Date(`${b.transaction_date}T${b.transaction_time || '00:00'}`);
        return dateB - dateA;
    });
    
    const filtered = sorted.filter(e => {
        const matchQuery = e.receiver_name.toLowerCase().includes(query) || 
                           (e.items && e.items.some(item => {
                               const name = typeof item === 'string' ? item : (item.name || '');
                               return name.toLowerCase().includes(query);
                           }));
        const matchCat = filterCat === 'all' || e.category.toLowerCase().trim() === filterCat.toLowerCase().trim();
        return matchQuery && matchCat;
    });
    
    el.expenseListContainer.innerHTML = '';
    
    if (filtered.length === 0) {
        el.expenseListContainer.innerHTML = `
            <div class="no-data-placeholder">
                <i class="fa-solid fa-magnifying-glass"></i>
                <p>ไม่พบรายการใช้จ่ายที่ตรงตามเงื่อนไขค้นหา</p>
            </div>
        `;
        return;
    }
    
    filtered.forEach(exp => {
        const catClass = getCategoryClass(exp.category);
        const catIcon = getCategoryIcon(exp.category);
        const formattedDate = new Date(exp.transaction_date).toLocaleDateString('th-TH', { day: 'numeric', month: 'short', year: 'numeric' });
        const itemsListHtml = renderNestedItemsList(exp.items);
        
        const cardHtml = `
            <div class="expense-item-card" id="card-${exp.id}">
                <div class="expense-summary" onclick="toggleCardExpand('${exp.id}')">
                    <div class="expense-info-left">
                        <div class="category-icon-box ${catClass}">
                            <i class="${catIcon}"></i>
                        </div>
                        <div>
                            <div class="receiver-name">${exp.receiver_name || 'ไม่ระบุผู้รับ'}</div>
                            <div class="transaction-datetime">${formattedDate} • ${exp.transaction_time || '00:00'} น.</div>
                        </div>
                    </div>
                    <div class="expense-info-right">
                        <div class="expense-amount">฿${parseFloat(exp.amount).toFixed(2)}</div>
                        <i class="fa-solid fa-chevron-down chevron-icon"></i>
                    </div>
                </div>
                
                <div class="expense-details-expanded">
                    <div class="expanded-meta-grid">
                        <div class="meta-item">
                            <span class="label">หมวดหมู่</span>
                            <span class="value">${getCategoryDisplayName(exp.category)}</span>
                        </div>
                        <div class="meta-item">
                            <span class="label">ธนาคาร / แหล่งจ่ายเงิน</span>
                            <span class="value">${exp.bank_name || 'บันทึกด้วยมือ'}</span>
                        </div>
                        ${exp.sender_name ? `
                        <div class="meta-item">
                            <span class="label">ผู้โอนเงิน</span>
                            <span class="value">${exp.sender_name}</span>
                        </div>
                        ` : ''}
                        ${exp.parsedProvider ? `
                        <div class="meta-item">
                            <span class="label">ประมวลผลโดย AI</span>
                            <span class="value">${exp.parsedProvider}</span>
                        </div>
                        ` : ''}
                    </div>
                    
                    ${itemsListHtml}
                    
                    ${exp.rawOcrText ? `
                    <div class="meta-item" style="margin-bottom: 12px;">
                        <span class="label">ข้อความดอกจากสลิป (Raw OCR)</span>
                        <div class="ocr-raw-block">${escapeHtml(exp.rawOcrText)}</div>
                    </div>
                    ` : ''}
                    
                    <div class="expanded-actions">
                        <button class="action-btn-small btn-edit" onclick="triggerEditExpense('${exp.id}')">
                            <i class="fa-solid fa-pen"></i> แก้ไข
                        </button>
                        <button class="action-btn-small btn-delete" onclick="triggerDeleteExpense('${exp.id}')">
                            <i class="fa-solid fa-trash-can"></i> ลบรายการ
                        </button>
                    </div>
                </div>
            </div>
        `;
        el.expenseListContainer.innerHTML += cardHtml;
    });
}

function getCategoryClass(cat) {
    const c = cat.toLowerCase().trim();
    if (['food', 'travel', 'utilities', 'shopping', 'entertainment', 'other'].includes(c)) {
        return `cat-${c}`;
    }
    return 'cat-custom';
}

function getCategoryIcon(cat) {
    switch (cat.toLowerCase().trim()) {
        case 'food': return 'fa-solid fa-burger';
        case 'travel': return 'fa-solid fa-car-side';
        case 'utilities': return 'fa-solid fa-bolt';
        case 'shopping': return 'fa-solid fa-bag-shopping';
        case 'entertainment': return 'fa-solid fa-film';
        case 'other': return 'fa-solid fa-box-open';
        default: return 'fa-solid fa-tags';
    }
}

function renderNestedItemsList(items) {
    if (!items || items.length === 0) return '';
    
    let rowsHtml = '';
    items.forEach(item => {
        if (typeof item === 'string') {
            rowsHtml += `
                <div class="nested-item-row">
                    <span class="name">${item}</span>
                    <span class="price">฿0.00</span>
                </div>
            `;
        } else {
            const qtyStr = (item.quantity && item.quantity > 1) ? `<span class="qty">x${item.quantity}</span>` : '';
            const price = parseFloat(item.price || 0);
            const total = price * (parseInt(item.quantity) || 1);
            rowsHtml += `
                <div class="nested-item-row">
                    <span class="name">${item.name || 'สินค้า'} ${qtyStr}</span>
                    <span class="price">฿${total.toFixed(2)}</span>
                </div>
            `;
        }
    });
    
    return `
        <div class="nested-items-list">
            <h4>รายการสินค้าย่อย</h4>
            ${rowsHtml}
        </div>
    `;
}

window.toggleCardExpand = function(id) {
    const card = document.getElementById(`card-${id}`);
    if (card) {
        card.classList.toggle('expanded');
    }
};

// --- 8. Network Operations (API Integrations & Health check) ---
async function checkBackendHealth() {
    try {
        const response = await fetch(`${state.apiBaseUrl}/api/health`);
        const data = await response.json();
        
        if (data.status === 'alive') {
            el.healthStatus.className = 'status-badge online';
            el.healthText.innerText = 'API พร้อมใช้งาน';
        } else {
            el.healthStatus.className = 'status-badge offline';
            el.healthText.innerText = 'API ขัดข้อง';
        }
    } catch (e) {
        console.error("Health check failed:", e);
        el.healthStatus.className = 'status-badge offline';
        el.healthText.innerText = 'ไม่สามารถเชื่อมต่อ API';
    }
}

async function loadRealTimeModels(providerId, selectElement, selectLoader, selectActiveModelValue) {
    const apiKey = state.apiKeys[providerId] || '';
    if (!apiKey && providerId !== 'freellm') {
        // Fallback to default lists
        populateDefaultModels(providerId, selectElement, selectActiveModelValue);
        return;
    }
    
    selectLoader.style.display = 'inline-block';
    
    try {
        const queryParams = new URLSearchParams({ provider: providerId });
        if (apiKey) queryParams.append('apiKey', apiKey);
        
        const response = await fetch(`${state.apiBaseUrl}/api/models?${queryParams}`);
        const data = await response.json();
        
        selectLoader.style.display = 'none';
        
        if (data.success && data.models && data.models.length > 0) {
            selectElement.innerHTML = '';
            data.models.forEach(model => {
                const isSelected = model === selectActiveModelValue ? 'selected' : '';
                selectElement.innerHTML += `<option value="${model}" ${isSelected}>${model}</option>`;
            });
        } else {
            populateDefaultModels(providerId, selectElement, selectActiveModelValue);
        }
    } catch (e) {
        console.error("Error fetching models:", e);
        selectLoader.style.display = 'none';
        populateDefaultModels(providerId, selectElement, selectActiveModelValue);
    }
}

function populateDefaultModels(providerId, selectElement, selectActiveModelValue) {
    const provider = AI_PROVIDERS.find(p => p.id === providerId);
    if (!provider) return;
    
    selectElement.innerHTML = '';
    provider.defaultFreeModels.forEach(model => {
        const isSelected = model === selectActiveModelValue ? 'selected' : '';
        selectElement.innerHTML += `<option value="${model}" ${isSelected}>${model}</option>`;
    });
}

// --- 9. Event Listeners Setup ---
function setupEventListeners() {
    // 9.1 Search & Filters
    el.searchInput.addEventListener('input', renderExpenseList);
    el.categoryFilter.addEventListener('change', renderExpenseList);
    
    // 9.2 Settings Modal Triggers
    el.openSettingsBtn.addEventListener('click', openSettingsModal);
    el.closeSettingsModal.addEventListener('click', () => el.settingsModal.classList.remove('active'));
    el.cancelSettingsBtn.addEventListener('click', () => el.settingsModal.classList.remove('active'));
    el.saveSettingsBtn.addEventListener('click', saveSettingsFromForm);
    
    // Change active provider triggers model reloading in settings
    el.settingsActiveProvider.addEventListener('change', () => {
        const selectedProvider = el.settingsActiveProvider.value;
        const currentActiveModelVal = selectedProvider === state.activeProvider ? state.activeModel : '';
        loadRealTimeModels(selectedProvider, el.settingsActiveModel, el.modelLoader, currentActiveModelVal);
    });
    
    // Test connection trigger
    el.testConnectionBtn.addEventListener('click', runConnectionTest);
    
    // 9.3 Budget Quick Modal
    el.editBudgetTrigger.addEventListener('click', () => {
        el.quickBudgetInput.value = state.budget;
        el.budgetQuickModal.classList.add('active');
    });
    el.closeBudgetModal.addEventListener('click', () => el.budgetQuickModal.classList.remove('active'));
    el.cancelBudgetBtn.addEventListener('click', () => el.budgetQuickModal.classList.remove('active'));
    el.saveBudgetBtn.addEventListener('click', () => {
        const newB = parseFloat(el.quickBudgetInput.value);
        if (!isNaN(newB) && newB >= 0) {
            state.budget = newB;
            localStorage.setItem('total_budget', newB);
            el.budgetQuickModal.classList.remove('active');
            updateDashboard();
        }
    });
    
    // 9.4 Category Creator
    el.addCategoryBtn.addEventListener('click', (e) => {
        e.preventDefault();
        const newCat = el.newCategoryInput.value.trim();
        if (newCat && !state.categories.includes(newCat)) {
            state.categories.push(newCat);
            el.newCategoryInput.value = '';
            renderSettingsCategoryTags();
            populateDropdowns();
            localStorage.setItem('saved_categories', JSON.stringify(state.categories));
        }
    });
    
    // 9.5 Backup Actions
    el.exportDataBtn.addEventListener('click', () => {
        const backupData = {
            total_budget: state.budget,
            saved_categories: state.categories,
            active_provider: state.activeProvider,
            active_model: state.activeModel,
            saved_expenses: state.expenses
        };
        const blob = new Blob([JSON.stringify(backupData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `expense_tracker_backup_${new Date().toISOString().split('T')[0]}.json`;
        link.click();
    });
    
    el.importDataTrigger.addEventListener('click', () => el.importDataFile.click());
    el.importDataFile.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = function(evt) {
            try {
                const parsed = JSON.parse(evt.target.result);
                if (parsed.total_budget !== undefined) state.budget = parseFloat(parsed.total_budget);
                if (parsed.saved_categories) state.categories = parsed.saved_categories;
                if (parsed.active_provider) state.activeProvider = parsed.active_provider;
                if (parsed.active_model) state.activeModel = parsed.active_model;
                if (parsed.saved_expenses) state.expenses = parsed.saved_expenses;
                
                // Save to storage
                localStorage.setItem('total_budget', state.budget);
                localStorage.setItem('saved_categories', JSON.stringify(state.categories));
                localStorage.setItem('active_provider', state.activeProvider);
                localStorage.setItem('active_model', state.activeModel);
                saveExpenses();
                
                alert("นำเข้าข้อมูลสำรองเรียบร้อยแล้ว!");
                populateDropdowns();
                updateDashboard();
                el.settingsModal.classList.remove('active');
            } catch (err) {
                alert("ไฟล์ข้อมูลสำรองไม่ถูกต้อง หรือเสียหาย: " + err.message);
            }
        };
        reader.readAsText(file);
    });
    
    // 9.6 Expense Modal trigger Add manually
    el.addManualBtn.addEventListener('click', () => {
        openExpenseFormModal();
    });
    el.closeExpenseModal.addEventListener('click', () => el.expenseModal.classList.remove('active'));
    el.cancelExpenseBtn.addEventListener('click', () => el.expenseModal.classList.remove('active'));
    el.addItemRowTrigger.addEventListener('click', () => addExpenseItemFormRow());
    el.expenseForm.addEventListener('submit', saveExpenseFromForm);
    
    // 9.7 AI Scan Trigger
    el.scanReceiptBtn.addEventListener('click', () => el.receiptFileInput.click());
    el.receiptFileInput.addEventListener('change', handleScanReceiptUpload);
}

// --- 10. Settings Logic ---
function openSettingsModal() {
    el.settingsApiUrl.value = state.apiBaseUrl;
    el.settingsBudget.value = state.budget;
    el.testResultBox.style.display = 'none';
    
    // Update active provider select
    el.settingsActiveProvider.value = state.activeProvider;
    
    // Reload dynamically active provider's models list
    loadRealTimeModels(state.activeProvider, el.settingsActiveModel, el.modelLoader, state.activeModel);
    
    // Render Keys Accordion and category tags
    renderApiKeysAccordion();
    renderSettingsCategoryTags();
    
    el.settingsModal.classList.add('active');
}

function renderSettingsCategoryTags() {
    el.categoryTagsContainer.innerHTML = '';
    state.categories.forEach(cat => {
        const tagHtml = `
            <span class="category-tag">
                ${getCategoryDisplayName(cat)}
                <button type="button" onclick="deleteCategoryFromSettings('${cat}')">&times;</button>
            </span>
        `;
        el.categoryTagsContainer.innerHTML += tagHtml;
    });
}

window.deleteCategoryFromSettings = function(catName) {
    if (['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'].includes(catName)) {
        alert("ขออภัย ไม่สามารถลบหมวดหมู่ระบบเริ่มต้นได้");
        return;
    }
    state.categories = state.categories.filter(c => c !== catName);
    renderSettingsCategoryTags();
    populateDropdowns();
    localStorage.setItem('saved_categories', JSON.stringify(state.categories));
};

function saveSettingsFromForm() {
    state.apiBaseUrl = el.settingsApiUrl.value.trim();
    state.activeProvider = el.settingsActiveProvider.value;
    state.activeModel = el.settingsActiveModel.value;
    state.budget = parseFloat(el.settingsBudget.value) || 15000;
    
    // Save keys from accordion
    document.querySelectorAll('.provider-key-input').forEach(input => {
        const pId = input.getAttribute('data-provider-id');
        const keyVal = input.value.trim();
        state.apiKeys[pId] = keyVal;
        localStorage.setItem(`key_${pId}`, keyVal);
    });
    
    localStorage.setItem('api_base_url', state.apiBaseUrl);
    localStorage.setItem('active_provider', state.activeProvider);
    localStorage.setItem('active_model', state.activeModel);
    localStorage.setItem('total_budget', state.budget);
    
    el.settingsModal.classList.remove('active');
    updateDashboard();
    checkBackendHealth();
}

async function runConnectionTest() {
    el.testResultBox.style.display = 'block';
    el.testResultBox.className = 'test-result-box';
    el.testResultBox.innerText = 'กำลังทดสอบการเรียกใช้งาน AI...';
    
    // Read temporarily filled form fields
    const testProvider = el.settingsActiveProvider.value;
    const testModel = el.settingsActiveModel.value;
    
    const keyInput = document.querySelector(`.provider-key-input[data-provider-id="${testProvider}"]`);
    const testKey = keyInput ? keyInput.value.trim() : '';
    
    try {
        const bodyMap = {
            data: "Test connection message. Respond with empty items list and valid JSON format.",
            isImage: false,
            provider: testProvider,
            model: testModel
        };
        if (testKey) bodyMap.apiKey = testKey;
        
        const response = await fetch(`${el.settingsApiUrl.value.trim()}/api/parse-receipt`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(bodyMap)
        });
        
        const data = await response.json();
        if (data.success) {
            el.testResultBox.className = 'test-result-box success';
            el.testResultBox.innerText = `เชื่อมต่อสำเร็จ!\nผู้ให้บริการ: ${data.provider.toUpperCase()}\nโมเดล: ${data.model}\nผลลัพธ์แยกข้อมูล: สำเร็จ! (สถานะ 200)`;
        } else {
            el.testResultBox.className = 'test-result-box error';
            el.testResultBox.innerText = `การเชื่อมต่อผิดพลาด:\n${data.error || 'ไม่มีคำตอบกลับจากเซิร์ฟเวอร์'}`;
        }
    } catch (e) {
        el.testResultBox.className = 'test-result-box error';
        el.testResultBox.innerText = `การส่งคำขอเครือข่ายล้มเหลว: ${e.message}`;
    }
}

// --- 11. Expense Form Modal (Add / Edit) Logic ---
function openExpenseFormModal(expense = null) {
    el.formItemsContainer.innerHTML = '';
    
    if (expense) {
        // Edit Mode
        el.expenseModalTitle.innerText = "แก้ไขรายการใช้จ่าย";
        el.formExpenseId.value = expense.id;
        el.formDate.value = expense.transaction_date;
        el.formTime.value = expense.transaction_time || '00:00';
        el.formAmount.value = expense.amount;
        el.formReceiver.value = expense.receiver_name || '';
        el.formCategory.value = expense.category;
        el.formBank.value = expense.bank_name || '';
        el.formRawOcr.value = expense.rawOcrText || '';
        
        if (expense.items && expense.items.length > 0) {
            expense.items.forEach(item => {
                if (typeof item === 'string') {
                    addExpenseItemFormRow(item, 0.0, 1);
                } else {
                    addExpenseItemFormRow(item.name, item.price, item.quantity);
                }
            });
        } else {
            addExpenseItemFormRow();
        }
    } else {
        // Add Mode
        el.expenseModalTitle.innerText = "บันทึกรายจ่ายรายการใหม่";
        el.formExpenseId.value = '';
        el.formDate.value = new Date().toISOString().split('T')[0];
        el.formTime.value = new Date().toTimeString().substring(0, 5);
        el.formAmount.value = '';
        el.formReceiver.value = '';
        el.formCategory.value = state.categories[0] || 'Other';
        el.formBank.value = '';
        el.formRawOcr.value = '';
        
        addExpenseItemFormRow();
    }
    
    el.expenseModal.classList.add('active');
}

function addExpenseItemFormRow(name = '', price = '', qty = 1) {
    const rowId = 'row-' + Math.random().toString(36).substring(2, 9);
    const rowHtml = `
        <div class="item-editor-row" id="${rowId}">
            <input type="text" class="item-row-name" placeholder="ชื่อสินค้า/บริการ..." value="${escapeHtml(name)}" required>
            <input type="number" class="item-row-price" step="0.01" placeholder="ราคา..." value="${price}" onchange="recalculateFormAmount()" required>
            <input type="number" class="item-row-qty" min="1" placeholder="จำนวน..." value="${qty}" onchange="recalculateFormAmount()" required>
            <button type="button" class="delete-row-btn" onclick="deleteExpenseItemFormRow('${rowId}')">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>
    `;
    el.formItemsContainer.innerHTML += rowHtml;
}

window.deleteExpenseItemFormRow = function(rowId) {
    const row = document.getElementById(rowId);
    if (row) {
        row.remove();
        recalculateFormAmount();
    }
};

window.recalculateFormAmount = function() {
    let total = 0.0;
    document.querySelectorAll('.item-editor-row').forEach(row => {
        const price = parseFloat(row.querySelector('.item-row-price').value) || 0.0;
        const qty = parseInt(row.querySelector('.item-row-qty').value) || 1;
        total += price * qty;
    });
    
    // Auto-update amount only if manual values sum > 0
    if (total > 0) {
        el.formAmount.value = total.toFixed(2);
    }
};

function saveExpenseFromForm(e) {
    e.preventDefault();
    
    const id = el.formExpenseId.value || 'web-' + Date.now().toString(36);
    const dateVal = el.formDate.value;
    const timeVal = el.formTime.value;
    const amountVal = parseFloat(el.formAmount.value) || 0.0;
    const receiverVal = el.formReceiver.value.trim();
    const categoryVal = el.formCategory.value;
    const bankVal = el.formBank.value.trim();
    const rawOcrVal = el.formRawOcr.value.trim();
    
    // Map items
    const items = [];
    document.querySelectorAll('.item-editor-row').forEach(row => {
        const name = row.querySelector('.item-row-name').value.trim();
        const price = parseFloat(row.querySelector('.item-row-price').value) || 0.0;
        const qty = parseInt(row.querySelector('.item-row-qty').value) || 1;
        
        if (name) {
            items.push({ name, price, quantity: qty });
        }
    });
    
    const isEdit = el.formExpenseId.value !== '';
    const newExpenseObj = {
        id,
        transaction_date: dateVal,
        transaction_time: timeVal,
        amount: amountVal,
        receiver_name: receiverVal,
        category: categoryVal,
        items,
        bank_name: bankVal || null,
        rawOcrText: rawOcrVal || '',
        parsedProvider: isEdit ? (state.expenses.find(e => e.id === id)?.parsedProvider || 'Manual') : 'Manual'
    };
    
    if (isEdit) {
        const idx = state.expenses.findIndex(e => e.id === id);
        if (idx !== -1) state.expenses[idx] = newExpenseObj;
    } else {
        state.expenses.push(newExpenseObj);
    }
    
    saveExpenses();
    el.expenseModal.classList.remove('active');
    updateDashboard();
}

window.triggerEditExpense = function(id) {
    const exp = state.expenses.find(e => e.id === id);
    if (exp) {
        openExpenseFormModal(exp);
    }
};

window.triggerDeleteExpense = function(id) {
    if (confirm("คุณแน่ใจว่าต้องการลบรายการใช้จ่ายนี้หรือไม่?")) {
        state.expenses = state.expenses.filter(e => e.id !== id);
        saveExpenses();
        updateDashboard();
    }
};

// --- 12. Receipt AI Parsing Logic ---
async function handleScanReceiptUpload(e) {
    const file = e.target.files[0];
    if (!file) return;
    
    // Clear value to allow scanning same file again
    el.receiptFileInput.value = '';
    
    el.aiLoadingOverlay.classList.add('active');
    el.loadingStepText.innerText = 'กำลังตรวจสอบไฟล์...';
    
    try {
        const base64Content = await fileToBase64(file);
        const isPdf = file.type === 'application/pdf' || file.name.endsWith('.pdf');
        const fileType = isPdf ? 'pdf' : 'image';
        
        // Validation check for PDF & Gemini provider
        if (isPdf && state.activeProvider !== 'gemini') {
            throw new Error("ไฟล์ PDF รอประมวลผลผ่านโมเดล Google Gemini เท่านั้น กรุณาตั้งค่าเปลี่ยน AI Provider ในระบบก่อนใช้งานสแกน PDF");
        }
        
        el.loadingStepText.innerText = `กำลังส่งไฟล์เข้าประมวลผลทาง AI (${state.activeProvider})...`;
        
        const payload = {
            data: base64Content,
            isImage: !isPdf,
            fileType: fileType,
            provider: state.activeProvider,
            model: state.activeModel
        };
        
        const apiKey = state.apiKeys[state.activeProvider];
        if (apiKey) payload.apiKey = apiKey;
        
        const response = await fetch(`${state.apiBaseUrl}/api/parse-receipt`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        const resData = await response.json();
        
        el.aiLoadingOverlay.classList.remove('active');
        
        if (resData.success && resData.data) {
            const parsed = resData.data;
            
            // Format mock elements for Expense mapping
            const tempExpense = {
                id: 'scan-' + Date.now().toString(36),
                transaction_date: parsed.transaction_date || new Date().toISOString().split('T')[0],
                transaction_time: parsed.transaction_time || '00:00',
                amount: parseFloat(parsed.amount) || 0.0,
                receiver_name: parsed.receiver_name || parsed.sender_name || 'ร้านค้าสแกนใบเสร็จ',
                category: parsed.category || 'Other',
                items: parsed.items || [],
                bank_name: parsed.bank_name || 'สแกนผ่าน ' + (resData.provider || state.activeProvider),
                rawOcrText: parsed.rawOcrText || `AI Parsed by ${resData.provider} / ${resData.model}`,
                parsedProvider: `${resData.provider} (${resData.model})`
            };
            
            // Open modal filled with parsed results for User Confirmation
            openExpenseFormModal(tempExpense);
            
        } else {
            throw new Error(resData.error || "ไม่สามารถแยกวิเคราะห์โครงสร้างสลิปได้");
        }
        
    } catch (err) {
        el.aiLoadingOverlay.classList.remove('active');
        alert("เกิดข้อผิดพลาดในการสแกนสลิปด้วย AI:\n" + err.message);
    }
}

// --- 13. General Helper Utilities ---
function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => {
            // Strip MIME type prefix (e.g. data:image/png;base64, )
            const rawBase64 = reader.result.split(',')[1];
            resolve(rawBase64);
        };
        reader.onerror = error => reject(error);
    });
}

function escapeHtml(string) {
    if (!string) return '';
    return String(string)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

// Start Application on Load
document.addEventListener('DOMContentLoaded', init);
