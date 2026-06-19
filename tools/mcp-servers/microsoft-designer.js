#!/usr/bin/env node

/**
 * Microsoft AI Image Generation MCP Server
 * Generates LinkedIn-optimized images using Azure AI backends
 * 
 * Supports:
 * - Azure OpenAI DALL-E 3: API key auth
 * - Azure AI Foundry DALL-E 3: API key auth  
 * - Azure AI Foundry MAI-Image-2e: Azure AD auth (DefaultAzureCredential)
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const { DefaultAzureCredential } = require('@azure/identity');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const server = new Server(
  {
    name: 'microsoft-designer',
    version: '2.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Global credential instance (reused across calls)
let azureCredential = null;

/**
 * Get Azure AD token for Foundry API
 */
async function getAzureToken() {
  if (!azureCredential) {
    azureCredential = new DefaultAzureCredential();
  }
  
  const tokenResponse = await azureCredential.getToken('https://ai.azure.com/.default');
  return tokenResponse.token;
}

/**
 * Detect backend type from endpoint URL
 */
function detectBackend(endpoint) {
  if (endpoint.includes('.services.ai.azure.com')) {
    return 'foundry-mai'; // Azure AI Foundry with MAI models
  } else if (endpoint.includes('.ai.azure.com/api/projects/')) {
    return 'foundry-mai-project'; // Azure AI Foundry project endpoint
  } else if (endpoint.includes('inference.ml.azure.com')) {
    return 'foundry-dalle'; // Azure AI Foundry with DALL-E
  } else if (endpoint.includes('openai.azure.com')) {
    return 'azure-openai'; // Direct Azure OpenAI
  } else {
    throw new Error(`Unknown endpoint: ${endpoint}`);
  }
}

/**
 * Generate image using Azure OpenAI DALL-E 3 (API key)
 */
async function generateWithAzureOpenAI(endpoint, apiKey, prompt) {
  const response = await axios.post(
    `${endpoint}/openai/deployments/dall-e-3/images/generations?api-version=2024-02-01`,
    {
      prompt: prompt.substring(0, 4000),
      n: 1,
      size: '1792x1024',
      quality: 'standard',
    },
    {
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
      },
      timeout: 90000,
    }
  );

  return {
    imageUrl: response.data.data[0].url,
    revisedPrompt: response.data.data[0].revised_prompt || prompt,
  };
}

/**
 * Generate image using Azure AI Foundry DALL-E 3 (API key)
 */
async function generateWithFoundryDALLE(endpoint, apiKey, prompt) {
  const url = endpoint.endsWith('/v1/images/generations') 
    ? endpoint 
    : `${endpoint}/v1/images/generations`;

  const response = await axios.post(
    url,
    {
      prompt: prompt.substring(0, 4000),
      n: 1,
      size: '1792x1024',
      quality: 'standard',
    },
    {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      timeout: 90000,
    }
  );

  return {
    imageUrl: response.data.data[0].url,
    revisedPrompt: response.data.data[0].revised_prompt || prompt,
  };
}

/**
 * Generate image using Azure AI Foundry MAI-Image (Azure AD auth)
 */
async function generateWithFoundryMAI(endpoint, modelName, prompt) {
  // Get Azure AD token
  const token = await getAzureToken();

  // Extract base endpoint (remove /api/projects/... if present)
  const baseEndpoint = endpoint.includes('/api/projects/') 
    ? endpoint.split('/api/projects/')[0]
    : endpoint;

  // Call MAI image generations API (Microsoft Learn format)
  const apiUrl = `${baseEndpoint}/mai/v1/images/generations`;
  
  const response = await axios.post(
    apiUrl,
    {
      model: modelName,
      prompt: prompt.substring(0, 32000), // Max 32K tokens per docs
      width: 1024,
      height: 1024,
    },
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      timeout: 90000,
    }
  );

  // MAI API returns base64-encoded PNG data
  // Response format: { data: [{ b64_json: "..." }] }
  if (response.data && response.data.data && response.data.data[0]) {
    const imageData = response.data.data[0];
    
    // Return base64 data (will be decoded by caller)
    return {
      imageBase64: imageData.b64_json || imageData.url,
      revisedPrompt: prompt, // MAI doesn't revise prompts
    };
  }
  
  throw new Error('Unexpected response format from MAI API');
}

// Tool: generate_linkedin_image
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'generate_linkedin_image',
        description: 'Generate LinkedIn post image using Azure AI (DALL-E 3 or MAI-Image-2.5). Creates 1792x1024 image optimized for LinkedIn.',
        inputSchema: {
          type: 'object',
          properties: {
            prompt: {
              type: 'string',
              description: 'Detailed image generation prompt (max 4000 chars)',
            },
            outputPath: {
              type: 'string',
              description: 'Absolute path where to save the generated image (PNG format)',
            },
          },
          required: ['prompt', 'outputPath'],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name !== 'generate_linkedin_image') {
    throw new Error(`Unknown tool: ${request.params.name}`);
  }

  const { prompt, outputPath } = request.params.arguments;

  // Check environment variables
  const endpoint = process.env.AZURE_AI_ENDPOINT;
  const apiKey = process.env.AZURE_AI_API_KEY; // Optional for MAI (uses Azure AD)
  const modelName = process.env.AZURE_AI_MODEL || 'MAI-Image-2.5';

  if (!endpoint) {
    throw new Error('AZURE_AI_ENDPOINT environment variable not set');
  }

  try {
    // Detect backend type
    const backend = detectBackend(endpoint);
    console.error(`Using ${backend} backend (model: ${modelName})`);

    let result;

    switch (backend) {
      case 'azure-openai':
        if (!apiKey) throw new Error('AZURE_AI_API_KEY required for Azure OpenAI');
        result = await generateWithAzureOpenAI(endpoint, apiKey, prompt);
        break;

      case 'foundry-dalle':
        if (!apiKey) throw new Error('AZURE_AI_API_KEY required for Foundry DALL-E');
        result = await generateWithFoundryDALLE(endpoint, apiKey, prompt);
        break;

      case 'foundry-mai':
      case 'foundry-mai-project':
        // Azure AD auth (no API key needed)
        result = await generateWithFoundryMAI(endpoint, modelName, prompt);
        break;

      default:
        throw new Error(`Unsupported backend: ${backend}`);
    }

    // Download or decode image
    let imageBuffer;
    
    if (result.imageBase64) {
      // MAI backends return base64-encoded PNG
      imageBuffer = Buffer.from(result.imageBase64, 'base64');
    } else if (result.imageUrl) {
      // DALL-E backends return URLs
      const imageResponse = await axios.get(result.imageUrl, {
        responseType: 'arraybuffer',
        timeout: 30000,
      });
      imageBuffer = imageResponse.data;
    } else {
      throw new Error('No image data or URL in response');
    }

    // Ensure output directory exists
    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // Save image
    fs.writeFileSync(outputPath, imageBuffer);

    return {
      content: [
        {
          type: 'text',
          text: `✅ Image generated and saved to ${outputPath}\n\nBackend: ${backend}\nModel: ${modelName}\n\nRevised prompt:\n${result.revisedPrompt}`,
        },
      ],
    };
  } catch (error) {
    const errorMsg = error.response?.data || error.message;
    console.error('Image generation error:', errorMsg);
    
    return {
      content: [
        {
          type: 'text',
          text: `❌ Image generation failed: ${JSON.stringify(errorMsg, null, 2)}\n\nEndpoint: ${endpoint}\nModel: ${modelName}`,
        },
      ],
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Microsoft AI Image Generation MCP server running');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
