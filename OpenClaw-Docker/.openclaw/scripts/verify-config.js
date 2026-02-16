const fs = require('fs');
const { execSync } = require('child_process');

function checkPlatformConfig(platform) {
  try {
    const script = '/scripts/check-env.sh';
    const output = execSync(
      `sudo ${script} ${platform}`,
      { 
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
      }
    );
    return JSON.parse(output);
  } catch (error) {
    return { configured: false, missing: [] };
  }
}

function verifyAll() {
  const platforms = ['feishu', 'dingtalk', 'qqbot', 'wecom', 'google', 'notion', 'twitter', 'reddit', 'ai'];
  const results = {};
  let allConfigured = true;

  console.log('🔍 验证所有平台配置...\n');

  platforms.forEach(platform => {
    const result = checkPlatformConfig(platform);
    results[platform] = result;
    
    if (!result.configured) {
      allConfigured = false;
      console.log(`⏳ ${platform.toUpperCase()}: 未配置`);
    } else {
      console.log(`✅ ${platform.toUpperCase()}: 已配置`);
    }
  });

  console.log('\n' + '='.repeat(50));

  if (allConfigured) {
    console.log('🎉 所有平台配置完成！');
    console.log('删除 INIT_TODO.md...');
    
    try {
      fs.unlinkSync('/home/node/.openclaw/INIT_TODO.md');
      console.log('✅ 初始化完成，建议重启容器');
    } catch (error) {
      console.log('⚠️  无法删除 INIT_TODO.md');
    }
  } else {
    console.log('⚠️  还有平台未完成配置');
    console.log('📖 查看待办事项: cat /home/node/.openclaw/INIT_TODO.md');
  }

  return allConfigured;
}

if (require.main === module) {
  verifyAll();
}

module.exports = { checkPlatformConfig, verifyAll };