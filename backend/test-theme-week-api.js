import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function testThemeWeekAPI() {
  try {
    console.log('🧪 Testing Theme Week API...');

    // 使用 node.js 的 fetch 或者通过 curl 测试
    const response = await fetch('http://localhost:3000/api/v1/theme-weeks/current');
    console.log('📊 API Response Status:', response.status);
    console.log('📊 API Response Headers:', Object.fromEntries(response.headers));

    if (response.ok) {
      const data = await response.json();
      console.log('✅ API Response Data:');
      console.log(JSON.stringify(data, null, 2));
    } else {
      const errorText = await response.text();
      console.log('❌ API Error:', errorText);
    }
  } catch (error) {
    console.error('💥 Test failed:', error.message);
  }
}

testThemeWeekAPI();