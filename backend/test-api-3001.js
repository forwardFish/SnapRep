const http = require('http');

function testThemeWeekAPI() {
  return new Promise((resolve, reject) => {
    console.log('🧪 Testing Theme Week API on port 3001...');

    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/v1/theme-weeks/current',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      console.log(`📊 Status Code: ${res.statusCode}`);
      console.log(`📊 Headers: ${JSON.stringify(res.headers)}`);

      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log('✅ Response Body:', data);
        try {
          const jsonData = JSON.parse(data);
          console.log('✅ Parsed JSON:', JSON.stringify(jsonData, null, 2));
        } catch (error) {
          console.log('⚠️  Response is not valid JSON');
        }
        resolve(data);
      });
    });

    req.on('error', (error) => {
      console.error('❌ Request failed:', error.message);
      reject(error);
    });

    req.end();
  });
}

testThemeWeekAPI().catch(console.error);