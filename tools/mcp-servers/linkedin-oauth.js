#!/usr/bin/env node

/**
 * LinkedIn MCP Server (personal profile only)
 *
 * 3-legged OAuth → posts text + optional image to the authenticated user's
 * LinkedIn feed via the UGC Posts API. Token is persisted to disk and reused
 * (~60 day lifetime).
 *
 * Tools:
 *   - linkedin_authorize       Run once to grant permissions
 *   - linkedin_token_status    Check whether a valid token is saved
 *   - post_to_linkedin         Post text (+ optional image) to your feed
 *
 * Required env vars (set in .vscode/mcp.json):
 *   - LINKEDIN_CLIENT_ID
 *   - LINKEDIN_CLIENT_SECRET
 *
 * LinkedIn app setup:
 *   - Product enabled: "Sign In with LinkedIn using OpenID Connect"
 *   - Product enabled: "Share on LinkedIn"
 *   - Authorized redirect URL: http://localhost:3000/callback
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const http = require('http');
const crypto = require('crypto');
const { exec } = require('child_process');

const REDIRECT_PORT = 3000;
const REDIRECT_URI = `http://localhost:${REDIRECT_PORT}/callback`;
const TOKEN_FILE = path.join(__dirname, '.linkedin-token.json');
const SCOPES = ['openid', 'profile', 'email', 'w_member_social'];

const server = new Server(
  { name: 'linkedin', version: '3.0.0' },
  { capabilities: { tools: {} } }
);

function loadToken() {
  if (!fs.existsSync(TOKEN_FILE)) return null;
  try {
    const data = JSON.parse(fs.readFileSync(TOKEN_FILE, 'utf8'));
    if (data.expires_at && Date.now() >= data.expires_at) return null;
    return data;
  } catch {
    return null;
  }
}

function saveToken(tokenData) {
  const expiresIn = tokenData.expires_in || 5184000;
  const persisted = {
    ...tokenData,
    expires_at: Date.now() + (expiresIn - 60) * 1000,
    saved_at: new Date().toISOString(),
  };
  fs.writeFileSync(TOKEN_FILE, JSON.stringify(persisted, null, 2));
  return persisted;
}

function openInBrowser(url) {
  if (process.platform === 'win32') exec(`start "" "${url}"`);
  else if (process.platform === 'darwin') exec(`open "${url}"`);
  else exec(`xdg-open "${url}"`);
}

async function runAuthFlow() {
  const clientId = process.env.LINKEDIN_CLIENT_ID;
  const clientSecret = process.env.LINKEDIN_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error('LINKEDIN_CLIENT_ID and LINKEDIN_CLIENT_SECRET env vars required');
  }

  const state = crypto.randomBytes(16).toString('hex');
  const authUrl =
    `https://www.linkedin.com/oauth/v2/authorization?` +
    `response_type=code&client_id=${clientId}&` +
    `redirect_uri=${encodeURIComponent(REDIRECT_URI)}&` +
    `state=${state}&scope=${encodeURIComponent(SCOPES.join(' '))}`;

  return new Promise((resolve, reject) => {
    let httpServer;
    const timeout = setTimeout(() => {
      try { httpServer && httpServer.close(); } catch {}
      reject(new Error('OAuth flow timed out after 5 minutes'));
    }, 5 * 60 * 1000);

    httpServer = http.createServer(async (req, res) => {
      try {
        const url = new URL(req.url, `http://localhost:${REDIRECT_PORT}`);
        if (url.pathname !== '/callback') { res.writeHead(404); res.end(); return; }

        const code = url.searchParams.get('code');
        const returnedState = url.searchParams.get('state');
        const error = url.searchParams.get('error');

        if (error) {
          res.writeHead(400, { 'Content-Type': 'text/html' });
          res.end(`<h1>LinkedIn authorization failed</h1><p>${error}: ${url.searchParams.get('error_description') || ''}</p>`);
          clearTimeout(timeout); httpServer.close();
          reject(new Error(`LinkedIn auth error: ${error}`));
          return;
        }
        if (returnedState !== state) {
          res.writeHead(400); res.end('State mismatch');
          clearTimeout(timeout); httpServer.close();
          reject(new Error('OAuth state mismatch'));
          return;
        }

        const tokenResp = await axios.post(
          'https://www.linkedin.com/oauth/v2/accessToken',
          new URLSearchParams({
            grant_type: 'authorization_code',
            code,
            redirect_uri: REDIRECT_URI,
            client_id: clientId,
            client_secret: clientSecret,
          }),
          { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        const saved = saveToken(tokenResp.data);

        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
          <html><body style="font-family: system-ui; padding: 2rem;">
          <h1>LinkedIn authorization successful</h1>
          <p>Token saved. You can close this tab and return to VS Code.</p>
          <p><small>Scopes granted: ${tokenResp.data.scope || '(none reported)'}</small></p>
          </body></html>
        `);

        clearTimeout(timeout); httpServer.close();
        resolve(saved);
      } catch (err) {
        res.writeHead(500); res.end('Error');
        clearTimeout(timeout);
        try { httpServer.close(); } catch {}
        reject(err);
      }
    });

    httpServer.listen(REDIRECT_PORT, () => {
      console.error(`OAuth callback listener on ${REDIRECT_URI}`);
      openInBrowser(authUrl);
    });
  });
}

function requireToken() {
  const tok = loadToken();
  if (!tok || !tok.access_token) {
    throw new Error('No LinkedIn token. Run the linkedin_authorize tool first.');
  }
  return tok.access_token;
}

async function getUserUrn(token) {
  const resp = await axios.get('https://api.linkedin.com/v2/userinfo', {
    headers: { Authorization: `Bearer ${token}` },
  });
  return `urn:li:person:${resp.data.sub}`;
}

async function uploadImage(token, ownerUrn, imagePath) {
  if (!fs.existsSync(imagePath)) {
    throw new Error(`Image file not found: ${imagePath}`);
  }

  const registerResp = await axios.post(
    'https://api.linkedin.com/v2/assets?action=registerUpload',
    {
      registerUploadRequest: {
        recipes: ['urn:li:digitalmediaRecipe:feedshare-image'],
        owner: ownerUrn,
        serviceRelationships: [
          { relationshipType: 'OWNER', identifier: 'urn:li:userGeneratedContent' },
        ],
      },
    },
    {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'X-Restli-Protocol-Version': '2.0.0',
      },
    }
  );

  const uploadUrl =
    registerResp.data.value.uploadMechanism[
      'com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest'
    ].uploadUrl;
  const asset = registerResp.data.value.asset;

  const imageData = fs.readFileSync(imagePath);
  const ext = path.extname(imagePath).toLowerCase();
  const contentType = ext === '.jpg' || ext === '.jpeg' ? 'image/jpeg' : 'image/png';

  await axios.put(uploadUrl, imageData, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': contentType,
    },
  });

  return asset;
}

async function createPost(token, authorUrn, text, imageAsset = null) {
  const post = {
    author: authorUrn,
    lifecycleState: 'PUBLISHED',
    specificContent: {
      'com.linkedin.ugc.ShareContent': {
        shareCommentary: { text },
        shareMediaCategory: imageAsset ? 'IMAGE' : 'NONE',
      },
    },
    visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' },
  };

  if (imageAsset) {
    post.specificContent['com.linkedin.ugc.ShareContent'].media = [
      {
        status: 'READY',
        description: { text: 'Post image' },
        media: imageAsset,
        title: { text: 'Illustration' },
      },
    ];
  }

  const resp = await axios.post('https://api.linkedin.com/v2/ugcPosts', post, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Restli-Protocol-Version': '2.0.0',
    },
  });

  return resp.data.id;
}

// ─── Tool registration ────────────────────────────────────────────────────

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: 'linkedin_authorize',
      description:
        'Run the LinkedIn 3-legged OAuth flow. Opens a browser tab, you sign in once, the token is saved to disk and reused for ~60 days.',
      inputSchema: { type: 'object', properties: {} },
    },
    {
      name: 'linkedin_token_status',
      description: 'Check whether a valid LinkedIn token is saved.',
      inputSchema: { type: 'object', properties: {} },
    },
    {
      name: 'post_to_linkedin',
      description:
        'Post text and optional image to your personal LinkedIn feed. Requires linkedin_authorize first.',
      inputSchema: {
        type: 'object',
        properties: {
          text: { type: 'string', description: 'Post text (max 3000 chars)' },
          imagePath: {
            type: 'string',
            description: 'Optional absolute path to image (PNG/JPG)',
          },
        },
        required: ['text'],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const name = request.params.name;
  const args = request.params.arguments || {};

  try {
    if (name === 'linkedin_authorize') {
      const saved = await runAuthFlow();
      return {
        content: [
          {
            type: 'text',
            text:
              `✅ LinkedIn authorization complete.\n\n` +
              `Token saved to: ${TOKEN_FILE}\n` +
              `Scopes granted: ${saved.scope || '(unknown)'}\n` +
              `Expires: ${new Date(saved.expires_at).toISOString()}`,
          },
        ],
      };
    }

    if (name === 'linkedin_token_status') {
      const tok = loadToken();
      if (!tok) {
        return {
          content: [
            { type: 'text', text: '❌ No valid LinkedIn token. Run linkedin_authorize.' },
          ],
        };
      }
      return {
        content: [
          {
            type: 'text',
            text:
              `✅ Token present.\n` +
              `Scopes: ${tok.scope || '(unknown)'}\n` +
              `Expires: ${new Date(tok.expires_at).toISOString()}`,
          },
        ],
      };
    }

    if (name === 'post_to_linkedin') {
      const token = requireToken();
      const userUrn = await getUserUrn(token);
      let asset = null;
      if (args.imagePath) asset = await uploadImage(token, userUrn, args.imagePath);
      const postId = await createPost(
        token,
        userUrn,
        String(args.text).substring(0, 3000),
        asset
      );

      return {
        content: [
          {
            type: 'text',
            text:
              `✅ Posted to your LinkedIn feed\n\n` +
              `Post ID: ${postId}\n` +
              `URL: https://www.linkedin.com/feed/update/${postId}/`,
          },
        ],
      };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (error) {
    const detail = error.response?.data || error.message || String(error);
    console.error('LinkedIn tool error:', detail);
    return {
      content: [
        {
          type: 'text',
          text:
            `❌ ${name} failed:\n` +
            (typeof detail === 'string' ? detail : JSON.stringify(detail, null, 2)) +
            `\n\nCommon causes:\n` +
            `- Token missing/expired → run linkedin_authorize\n` +
            `- Redirect URI mismatch → ensure ${REDIRECT_URI} is registered in your LinkedIn app\n` +
            `- "Share on LinkedIn" product not enabled in LinkedIn app`,
        },
      ],
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('LinkedIn MCP server (personal) running');
}

main().catch((err) => {
  console.error('Server error:', err);
  process.exit(1);
});
