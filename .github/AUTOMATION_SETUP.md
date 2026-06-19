# LinkedIn Automation Setup Guide

## Overview

Automate the complete LinkedIn posting workflow:
1. **Image generation** using Microsoft Designer or DALL-E API
2. **LinkedIn posting** via Zapier MCP server
3. **Agent orchestration** to coordinate the workflow

## Architecture

```
Blog Post (draft: false)
    ↓
LinkedIn Poster Agent
    ↓
    ├─→ Image Generation (Microsoft Designer / DALL-E)
    │   └─→ Save to social/linkedin/<slug>/image.png
    └─→ LinkedIn Post (Zapier MCP)
        └─→ Upload image + text
```

## Prerequisites

- LinkedIn Premium account (for API access)
- M365 Copilot account (for Microsoft Designer)
- Zapier account (free tier works)

## Step 1: Install MCP Servers

### 1.1 Install Zapier MCP Server

```powershell
# Install via npm
npm install -g @zapier/mcp-server
```

### 1.2 Configure MCP in VS Code

Create or update `.vscode/settings.json`:

```json
{
  "github.copilot.chat.mcp.servers": {
    "zapier": {
      "command": "npx",
      "args": ["@zapier/mcp-server"],
      "env": {
        "ZAPIER_API_KEY": "<your-zapier-api-key>"
      }
    }
  }
}
```

### 1.3 Get Zapier API Key

1. Sign up at https://zapier.com
2. Go to https://zapier.com/app/settings/developer
3. Create a new API key
4. Copy key to settings above

## Step 2: Set Up Zapier LinkedIn Integration

### 2.1 Create LinkedIn Zap

In Zapier web interface:

1. **Trigger**: Webhooks by Zapier → Catch Hook
2. **Action**: LinkedIn → Create Share Update
   - Connect your LinkedIn Premium account
   - Map fields:
     - Text: `{{text}}`
     - Image URL: `{{imageUrl}}`

3. Copy the webhook URL (looks like: `https://hooks.zapier.com/hooks/catch/12345/abcdef/`)

### 2.2 Store Webhook URL

Add to `.vscode/settings.json`:

```json
{
  "github.copilot.chat.mcp.servers": {
    "zapier": {
      "env": {
        "ZAPIER_API_KEY": "<your-key>",
        "LINKEDIN_WEBHOOK_URL": "https://hooks.zapier.com/hooks/catch/12345/abcdef/"
      }
    }
  }
}
```

## Step 3: Image Generation Options

### Option A: Microsoft Designer API (Recommended)

Since you have M365 Copilot, use Microsoft Designer:

```json
{
  "github.copilot.chat.mcp.servers": {
    "microsoft-designer": {
      "command": "node",
      "args": ["./tools/mcp-servers/microsoft-designer.js"],
      "env": {
        "AZURE_OPENAI_API_KEY": "<your-key>",
        "AZURE_OPENAI_ENDPOINT": "<your-endpoint>"
      }
    }
  }
}
```

### Option B: DALL-E API

If Designer isn't available, use DALL-E:

```json
{
  "github.copilot.chat.mcp.servers": {
    "openai": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-openai"],
      "env": {
        "OPENAI_API_KEY": "<your-openai-key>"
      }
    }
  }
}
```

## Step 4: Custom MCP Server for Microsoft Designer

Create `tools/mcp-servers/microsoft-designer.js`:

```javascript
#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const axios = require('axios');
const fs = require('fs');

const server = new Server(
  { name: 'microsoft-designer', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

// Tool: generate_linkedin_image
server.setRequestHandler('tools/list', async () => ({
  tools: [{
    name: 'generate_linkedin_image',
    description: 'Generate LinkedIn post image using Microsoft Designer / DALL-E',
    inputSchema: {
      type: 'object',
      properties: {
        prompt: { type: 'string', description: 'Image generation prompt' },
        outputPath: { type: 'string', description: 'Path to save generated image' }
      },
      required: ['prompt', 'outputPath']
    }
  }]
}));

server.setRequestHandler('tools/call', async (request) => {
  if (request.params.name === 'generate_linkedin_image') {
    const { prompt, outputPath } = request.params.arguments;
    
    // Call Azure OpenAI DALL-E 3
    const response = await axios.post(
      `${process.env.AZURE_OPENAI_ENDPOINT}/openai/deployments/dall-e-3/images/generations?api-version=2024-02-01`,
      {
        prompt: prompt,
        n: 1,
        size: '1792x1024' // LinkedIn optimal
      },
      {
        headers: {
          'api-key': process.env.AZURE_OPENAI_API_KEY,
          'Content-Type': 'application/json'
        }
      }
    );
    
    const imageUrl = response.data.data[0].url;
    
    // Download and save image
    const imageResponse = await axios.get(imageUrl, { responseType: 'arraybuffer' });
    fs.writeFileSync(outputPath, imageResponse.data);
    
    return {
      content: [{
        type: 'text',
        text: `Image generated and saved to ${outputPath}`
      }]
    };
  }
});

const transport = new StdioServerTransport();
server.connect(transport);
```

Install dependencies:

```powershell
cd tools/mcp-servers
npm init -y
npm install @modelcontextprotocol/sdk axios
```

## Step 5: Update LinkedIn Poster Agent

Update `.github/agents/linkedin-poster.agent.md`:

```markdown
## Workflow

When a blog post changes from `draft: true` to `draft: false`:

1. **Read the published post** to extract title, content, and tags
2. **Generate LinkedIn image**:
   - Read `social/linkedin/<slug>/image-prompt.md`
   - Call `generate_linkedin_image` tool with prompt
   - Save to `social/linkedin/<slug>/image.png`
3. **Create LinkedIn post text** (existing behavior)
4. **Upload image to public URL**:
   - Use GitHub raw URL: `https://raw.githubusercontent.com/pdtit/pdtit.github.io/main/social/linkedin/<slug>/image.png`
5. **Post to LinkedIn**:
   - Call Zapier webhook with text and image URL
   - Confirm successful posting

## Tools Required

- `generate_linkedin_image` (Microsoft Designer MCP server)
- `zapier_webhook` (Zapier MCP server)
- Standard file operations

## Example Invocation

```javascript
// 1. Generate image
const imagePath = `social/linkedin/${slug}/image.png`;
await generate_linkedin_image({
  prompt: fs.readFileSync(`social/linkedin/${slug}/image-prompt.md`, 'utf8'),
  outputPath: imagePath
});

// 2. Commit and push image to GitHub
await run_in_terminal(`git add "${imagePath}" && git commit -m "Add LinkedIn image for ${slug}" && git push`);

// 3. Post to LinkedIn via Zapier
const imageUrl = `https://raw.githubusercontent.com/pdtit/pdtit.github.io/main/${imagePath}`;
await zapier_webhook({
  url: process.env.LINKEDIN_WEBHOOK_URL,
  data: {
    text: postContent,
    imageUrl: imageUrl
  }
});
```
```

## Step 6: Testing

1. **Test image generation**:
   ```powershell
   node tools/mcp-servers/microsoft-designer.js
   # In Copilot chat:
   # "Generate a test image using the prompt from social/linkedin/<slug>/image-prompt.md"
   ```

2. **Test Zapier webhook**:
   ```powershell
   Invoke-RestMethod -Uri "https://hooks.zapier.com/hooks/catch/12345/abcdef/" `
     -Method POST `
     -ContentType "application/json" `
     -Body (@{text="Test post"; imageUrl="https://example.com/image.png"} | ConvertTo-Json)
   ```

3. **Full workflow test**:
   - Create a draft post
   - Change `draft: false`
   - Invoke LinkedIn Poster agent
   - Check LinkedIn for published post

## Security Notes

- **Never commit API keys** to the repository
- Store all keys in `.vscode/settings.json` (add to .gitignore)
- Use GitHub Secrets for CI/CD workflows
- LinkedIn API has rate limits (Premium: 100 posts/day)

## Troubleshooting

### Image generation fails
- Check Azure OpenAI endpoint and key
- Verify DALL-E 3 deployment exists
- Check prompt length (<4000 chars)

### LinkedIn posting fails
- Check Zapier webhook URL
- Verify LinkedIn account connected in Zapier
- Check image URL is publicly accessible
- LinkedIn images must be <5MB, 1200x627 to 1200x1200 px

### MCP server not detected
- Restart VS Code after updating settings.json
- Check MCP server process in Task Manager
- Run MCP server manually to see errors

## Alternative: Direct LinkedIn API

If Zapier limits are too restrictive, use LinkedIn API directly:

1. **Register LinkedIn app**: https://www.linkedin.com/developers/apps
2. **Get OAuth 2.0 credentials**
3. **Create custom MCP server** for LinkedIn Posts API

See `tools/mcp-servers/linkedin-api.js` (TODO) for implementation.

## Cost Estimates

- **Zapier**: Free tier (100 tasks/month) or $19.99/month (750 tasks)
- **DALL-E 3**: ~$0.04 per image (1024x1024) or $0.08 (1792x1024)
- **LinkedIn API**: Free with Premium account
- **Storage**: GitHub free tier (1GB)

## Next Steps

1. Install Zapier MCP server
2. Configure Zapier LinkedIn integration
3. Set up image generation (Microsoft Designer or DALL-E)
4. Update LinkedIn Poster agent
5. Test with next blog post
