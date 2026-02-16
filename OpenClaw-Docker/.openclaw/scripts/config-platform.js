const fs = require('fs');
const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// 平台配置模板
const PLATFORM_TEMPLATES = {
  feishu: {
    name: '飞书',
    envVars: ['FEISHU_APP_ID', 'FEISHU_APP_SECRET'],
    questions: [
      { key: 'FEISHU_APP_ID', prompt: '请输入飞书 App ID: ' },
      { key: 'FEISHU_APP_SECRET', prompt: '请输入飞书 App Secret: ' }
    ]
  },
  dingtalk: {
    name: '钉钉',
    envVars: ['DINGTALK_CLIENT_ID', 'DINGTALK_CLIENT_SECRET', 'DINGTALK_ROBOT_CODE', 'DINGTALK_AGENT_ID'],
    questions: [
      { key: 'DINGTALK_CLIENT_ID', prompt: '请输入钉钉 Client ID: ' },
      { key: 'DINGTALK_CLIENT_SECRET', prompt: '请输入钉钉 Client Secret: ' },
      { key: 'DINGTALK_ROBOT_CODE', prompt: '请输入钉钉 Robot Code (默认与 Client ID 相同): ', default: 'DINGTALK_CLIENT_ID' },
      { key: 'DINGTALK_AGENT_ID', prompt: '请输入钉钉 Agent ID: ' }
    ]
  },
  qqbot: {
    name: 'QQ 机器人',
    envVars: ['QQBOT_APP_ID', 'QQBOT_CLIENT_SECRET'],
    questions: [
      { key: 'QQBOT_APP_ID', prompt: '请输入 QQ Bot App ID: ' },
      { key: 'QQBOT_CLIENT_SECRET', prompt: '请输入 QQ Bot Client Secret: ' }
    ]
  },
  wecom: {
    name: '企业微信',
    envVars: ['WECOM_TOKEN', 'WECOM_ENCODING_AES_KEY'],
    questions: [
      { key: 'WECOM_TOKEN', prompt: '请输入企业微信 Token: ' },
      { key: 'WECOM_ENCODING_AES_KEY', prompt: '请输入企业微信 Encoding AES Key: ' }
    ]
  },
  google: {
    name: 'Google',
    envVars: ['GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET', 'GOOGLE_REDIRECT_URI'],
    questions: [
      { key: 'GOOGLE_CLIENT_ID', prompt: '请输入 Google Client ID: ' },
      { key: 'GOOGLE_CLIENT_SECRET', prompt: '请输入 Google Client Secret: ' },
      { key: 'GOOGLE_REDIRECT_URI', prompt: '请输入 Google Redirect URI (默认: http://localhost:18789/callback/google): ', default: 'http://localhost:18789/callback/google' }
    ]
  },
  notion: {
    name: 'Notion',
    envVars: ['NOTION_INTEGRATION_TOKEN'],
    questions: [
      { key: 'NOTION_INTEGRATION_TOKEN', prompt: '请输入 Notion Integration Token: ' }
    ]
  },
  twitter: {
    name: 'X/Twitter',
    envVars: ['TWITTER_API_KEY', 'TWITTER_API_SECRET', 'TWITTER_ACCESS_TOKEN', 'TWITTER_ACCESS_SECRET', 'TWITTER_BEARER_TOKEN'],
    questions: [
      { key: 'TWITTER_API_KEY', prompt: '请输入 Twitter API Key: ' },
      { key: 'TWITTER_API_SECRET', prompt: '请输入 Twitter API Secret: ' },
      { key: 'TWITTER_ACCESS_TOKEN', prompt: '请输入 Twitter Access Token: ' },
      { key: 'TWITTER_ACCESS_SECRET', prompt: '请输入 Twitter Access Secret: ' },
      { key: 'TWITTER_BEARER_TOKEN', prompt: '请输入 Twitter Bearer Token: ' }
    ]
  },
  reddit: {
    name: 'Reddit',
    envVars: ['REDDIT_CLIENT_ID', 'REDDIT_CLIENT_SECRET', 'REDDIT_USER_AGENT'],
    questions: [
      { key: 'REDDIT_CLIENT_ID', prompt: '请输入 Reddit Client ID: ' },
      { key: 'REDDIT_CLIENT_SECRET', prompt: '请输入 Reddit Client Secret: ' },
      { key: 'REDDIT_USER_AGENT', prompt: '请输入 Reddit User Agent: ' }
    ]
  },
  ai: {
    name: 'AI Provider',
    envVars: ['MODEL_ID', 'BASE_URL', 'API_KEY', 'API_PROTOCOL', 'CONTEXT_WINDOW', 'MAX_TOKENS'],
    questions: [
      { key: 'MODEL_ID', prompt: '请输入 AI 模型 ID (如 gpt-4, claude-3-sonnet): ' },
      { key: 'BASE_URL', prompt: '请输入 API Base URL: ' },
      { key: 'API_KEY', prompt: '请输入 API Key: ' },
      { key: 'API_PROTOCOL', prompt: '请输入 API 协议 (openai-completions/anthropic-messages): ', default: 'openai-completions' },
      { key: 'CONTEXT_WINDOW', prompt: '请输入上下文窗口大小 (默认: 200000): ', default: '200000' },
      { key: 'MAX_TOKENS', prompt: '请输入最大输出 tokens (默认: 8192): ', default: '8192' }
    ]
  }
};

function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, (answer) => {
      resolve(answer);
    });
  });
}

async function collectCredentials(platform) {
  const template = PLATFORM_TEMPLATES[platform];
  if (!template) {
    console.error(`❌ 未知平台: ${platform}`);
    console.log(`支持的平台: ${Object.keys(PLATFORM_TEMPLATES).join(', ')}`);
    rl.close();
    process.exit(1);
  }

  console.log(`\n🔧 配置 ${template.name}\n`);

  const credentials = {};
  const tempValues = {};

  for (const q of template.questions) {
    let answer = await question(q.prompt);
    
    if (!answer && q.default) {
      if (q.default.startsWith('DINGTALK_CLIENT_ID')) {
        answer = tempValues.DINGTALK_CLIENT_ID;
      } else {
        answer = q.default;
      }
    }
    
    credentials[q.key] = answer;
    tempValues[q.key] = answer;
  }

  rl.close();

  return credentials;
}

function writeCredentials(platform, credentials) {
  const envContent = Object.entries(credentials)
    .map(([key, value]) => `${key}=${value}`)
    .join('\n');

  try {
    // 通过授权脚本安全写入
    const script = '/scripts/write-env.sh';
    const result = execSync(
      `sudo ${script} ${platform} <<'EOF'\n${envContent}\nEOF`,
      { 
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
      }
    );
    
    console.log(result);
    return true;
  } catch (error) {
    console.error(`❌ 写入配置失败: ${error.message}`);
    return false;
  }
}

function auditLog(platform, action, details = {}) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    platform,
    action,
    details
  };

  try {
    execSync(
      `sudo bash -c 'echo "${JSON.stringify(logEntry)}" >> /var/log/openclaw-audit.log'`,
      { stdio: 'pipe' }
    );
  } catch (error) {
    console.error(`⚠️  审计日志写入失败: ${error.message}`);
  }
}

async function main() {
  const platform = process.argv[2];

  if (!platform) {
    console.log('🔧 OpenClaw 平台配置工具\n');
    console.log('用法: node config-platform.js <platform>');
    console.log(`支持的平台: ${Object.keys(PLATFORM_TEMPLATES).join(', ')}`);
    console.log('\n示例:');
    console.log('  node config-platform.js feishu');
    console.log('  node config-platform.js google');
    console.log('  node config-platform.js ai\n');
    process.exit(0);
  }

  console.log(`🚀 开始配置 ${platform}...`);

  const credentials = await collectCredentials(platform);
  
  if (writeCredentials(platform, credentials)) {
    console.log(`\n✅ ${PLATFORM_TEMPLATES[platform].name} 配置完成`);
    auditLog(platform, 'configure', { envVars: Object.keys(credentials) });
    
    console.log('\n下一步操作:');
    console.log('  1. 重启容器使配置生效: docker restart openclaw-gateway');
    console.log('  2. 查看日志: docker logs -f openclaw-gateway');
    console.log('  3. 继续配置其他平台: node /home/node/.openclaw/scripts/config-platform.js <platform>');
  } else {
    console.log(`\n❌ ${PLATFORM_TEMPLATES[platform].name} 配置失败`);
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error('❌ 配置过程出错:', error);
    process.exit(1);
  });
}

module.exports = { PLATFORM_TEMPLATES, collectCredentials, writeCredentials };