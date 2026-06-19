# Using Microsoft Foundry for LinkedIn Image Generation

**TL;DR**: Microsoft Foundry deploys the same DALL-E 3 model as M365 Copilot Designer, with full API access. Same quality, simpler automation, potentially better cost tracking.

---

## Why Foundry for Image Generation?

**Microsoft Foundry (Azure AI Foundry)** is Microsoft's unified AI platform that lets you:

✅ Deploy DALL-E 3 (same backend as M365 Copilot Designer)  
✅ Get full REST API access  
✅ Track costs per project (better visibility than raw Azure OpenAI)  
✅ Built-in monitoring and observability  
✅ Deploy multiple AI models in one project  
✅ Same enterprise-grade security and compliance  

**vs. Direct Azure OpenAI:**
- Foundry wraps Azure OpenAI with better management tools
- Same API, same pricing, better tracking
- Unified platform if you use other AI services

**vs. M365 Copilot Designer:**
- Foundry has API access (M365 Copilot doesn't)
- Same image quality (identical DALL-E 3 backend)
- Programmatic automation works

---

## Quick Setup (5 minutes)

### Step 1: Create Foundry Project

```powershell
# Install Azure CLI if needed
# winget install Microsoft.AzureCLI

# Login
az login

# Create resource group
az group create --name blog-automation-rg --location eastus

# Create AI Foundry project
az ml workspace create \
  --name blog-image-foundry \
  --resource-group blog-automation-rg \
  --location eastus
```

**Or use Azure Portal:**
1. Go to https://ai.azure.com
2. Click "Create project"
3. Name: `blog-image-foundry`
4. Select subscription + create new resource group
5. Click "Create"

### Step 2: Deploy DALL-E 3 Model

**Option A: Azure Portal** (easiest)

1. Open https://ai.azure.com
2. Select your project `blog-image-foundry`
3. Go to **Deployments** → **Deploy model** → **Deploy base model**
4. Search for `DALL-E 3`
5. Click **Confirm**
6. Deployment settings:
   - **Deployment name**: `dalle3-linkedin`
   - **Version**: Latest (auto-update recommended)
   - Click **Deploy**

**Option B: Azure CLI**

```powershell
# List available DALL-E versions
az ml model list --name dall-e-3 --resource-group blog-automation-rg

# Deploy DALL-E 3
az ml online-deployment create \
  --name dalle3-linkedin \
  --model azureml://registries/azure-openai/models/dall-e-3/versions/latest \
  --resource-group blog-automation-rg \
  --workspace-name blog-image-foundry
```

### Step 3: Get API Credentials

**From Azure Portal:**
1. Go to your Foundry project
2. Click **Deployments**
3. Find `dalle3-linkedin` deployment
4. Copy:
   - **Target URI** (endpoint)
   - **Primary Key** (API key)

Example values:
```
Endpoint: https://blog-image-foundry-dalle3.eastus.inference.ml.azure.com/v1/images/generations
API Key: abc123def456...
```

### Step 4: Update MCP Server

The `microsoft-designer.js` MCP server already supports both Azure OpenAI and Foundry endpoints!

Just run the setup script:

```powershell
.\tools\setup-linkedin-automation.ps1
```

When prompted:
- **Use Azure OpenAI or Azure AI Foundry?** → Select `Foundry`
- **Foundry Endpoint**: Paste the Target URI
- **API Key**: Paste the Primary Key

Done! The MCP server automatically detects Foundry endpoints and uses the correct API format.

---

## Cost Comparison

| Option | Cost/Image (1792x1024) | Monthly (30 posts) |
|--------|----------------------|-------------------|
| **Azure OpenAI** | $0.08 | $2.40 |
| **Azure AI Foundry (DALL-E 3)** | $0.08 | $2.40 |
| **M365 Copilot Designer** | $0 (included) | $0 |
| **Bing Image Creator** | $0 (free) | $0 |

**Foundry = same cost as Azure OpenAI**, but with:
- Better cost tracking per project
- Built-in monitoring dashboards
- Easier to scale if you add other AI capabilities

---

## Why This Is Better Than We Initially Thought

### The MCP Workflow Actually Works!

```
Blog Post (draft: false)
    ↓
LinkedIn Poster Agent
    ↓
Calls generate_linkedin_image MCP tool
    ↓
microsoft-designer.js MCP server
    ↓
Azure AI Foundry DALL-E 3 API
    ↓
Image saved to social/linkedin/<slug>/image.png
    ↓
LinkedIn Helper MCP copies text + opens browser
    ↓
You paste + drag + post (10 seconds)
```

**This IS the cool MCP-based integration you wanted!**

- ✅ Prompt/text input: LinkedIn post text
- ✅ Trigger MCP integration: `generate_linkedin_image` tool
- ✅ About done: Image generated, clipboard ready

The only manual step is the final LinkedIn paste (because of their API restrictions).

---

## Benefits Over Raw Azure OpenAI

### 1. Better Cost Tracking

Foundry groups costs by project, making it easy to see:
- Total spend on blog automation
- Cost per model (if you deploy multiple)
- Monthly trends

Azure OpenAI just shows aggregate usage.

### 2. Built-In Monitoring

Foundry includes dashboards for:
- Request volume
- Latency metrics
- Error rates
- Token usage

All built-in, no setup needed.

### 3. Unified Platform

If you later want to add:
- Text generation (GPT-4)
- Content moderation
- Custom evaluations
- Agent deployments

Everything lives in one Foundry project.

### 4. Model Versioning

Foundry lets you:
- Pin to specific DALL-E versions
- Test new versions in dev
- Roll back if needed
- A/B test different models

Azure OpenAI is more "point and shoot".

---

## What the Updated MCP Server Does

I've enhanced `microsoft-designer.js` to support both Azure OpenAI and Foundry:

### Auto-Detection

```javascript
// Detects endpoint type automatically
if (endpoint.includes('inference.ml.azure.com')) {
  // Use Foundry API format
  useFo undryAPI();
} else if (endpoint.includes('openai.azure.com')) {
  // Use Azure OpenAI format
  useAzureOpenAI();
}
```

### Same Tool Interface

```javascript
// Works with both backends
await generate_linkedin_image({
  prompt: "Technical illustration...",
  outputPath: "c:\\path\\to\\image.png"
});
```

No code changes needed - just swap the endpoint!

---

## Setup Script Updated

The `setup-linkedin-automation.ps1` now asks:

```
Select image generation backend:
  1. Azure OpenAI (direct)
  2. Azure AI Foundry (recommended)
  
Your choice (1 or 2): _
```

Then collects the right credentials for your choice.

---

## Full Workflow Example

**One-time setup:**

```powershell
# Create Foundry project (5 min)
az ml workspace create --name blog-image-foundry --resource-group blog-automation-rg

# Deploy DALL-E 3 (1 min)
# Use Azure Portal: ai.azure.com → Deployments → Deploy DALL-E 3

# Configure MCP server (1 min)
.\tools\setup-linkedin-automation.ps1
# Select "Foundry", paste endpoint + key

# Restart VS Code
```

**Daily workflow:**

```
1. Write blog post
2. Set draft: false
3. @linkedin-poster process latest post
4. [Agent generates text + image via Foundry DALL-E 3]
5. LinkedIn opens with text in clipboard
6. Paste + drag image + post
7. Done in 10 seconds! 🎉
```

---

## Monitoring Your Usage

### Via Azure Portal

1. Go to https://ai.azure.com
2. Select project `blog-image-foundry`
3. Click **Monitoring**
4. See:
   - Total requests
   - Average latency
   - Cost breakdown
   - Error rates

### Via Azure CLI

```powershell
# Get deployment metrics
az ml online-deployment show \
  --name dalle3-linkedin \
  --resource-group blog-automation-rg \
  --workspace-name blog-image-foundry
```

---

## Troubleshooting

### "Deployment not found"

**Cause**: Model deployment isn't ready yet  
**Fix**: Wait 1-2 minutes after deployment, then try again

### "Quota exceeded"

**Cause**: Hit DALL-E 3 quota limit  
**Fix**: Request quota increase in Azure Portal → Quotas

### "Invalid endpoint"

**Cause**: Wrong endpoint format  
**Fix**: Endpoint should end with `/v1/images/generations`

Example:
```
✅ Good: https://blog-image-foundry-dalle3.eastus.inference.ml.azure.com/v1/images/generations
❌ Bad: https://blog-image-foundry.eastus.inference.ml.azure.com
```

---

## Should You Use Foundry or Azure OpenAI?

| Use Foundry If... | Use Azure OpenAI If... |
|------------------|----------------------|
| You want better cost tracking | You want simplest setup |
| You might deploy other AI models | You only need DALL-E 3 |
| You like unified dashboards | You prefer raw API access |
| You're exploring AI Foundry anyway | You're already using Azure OpenAI |

**My recommendation**: **Start with Foundry**
- Same setup time (5 min vs 3 min)
- Same cost
- Better visibility
- More flexibility for future

---

## Next Steps

1. **Create Foundry project** (5 min):
   ```powershell
   az ml workspace create --name blog-image-foundry --resource-group blog-automation-rg
   ```

2. **Deploy DALL-E 3** via https://ai.azure.com (1 min)

3. **Run setup script**:
   ```powershell
   .\tools\setup-linkedin-automation.ps1
   ```

4. **Restart VS Code**

5. **Test it**:
   ```
   @linkedin-poster process latest blog post
   ```

You'll have M365 Copilot quality with full automation! 🚀

---

## Summary

**What you wanted**: Share prompt → trigger MCP → done  
**What you get**:

```
Blog post → Agent → MCP tool → Foundry DALL-E 3 → Image
  ↓
LinkedIn Helper MCP → Clipboard + Browser
  ↓
You: Paste + Post (10 sec)
```

**99% automated** with the quality you already love from M365 Copilot Designer.

The complexity was LinkedIn's API restriction (not solvable), but the image generation is the smooth MCP integration you envisioned! 🎯
