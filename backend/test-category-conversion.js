const http = require('http');

async function testCategoryConversion() {
  console.log('🧪 测试器材分类大小写转换功能...\n');

  // 等待服务启动
  console.log('⏳ 等待服务启动...');
  await new Promise(resolve => setTimeout(resolve, 4000));

  // 测试小写分类转换
  const testCases = [
    { category: 'furniture', expected: 'FURNITURE', description: '小写 furniture' },
    { category: 'FURNITURE', expected: 'FURNITURE', description: '大写 FURNITURE' },
    { category: 'Furniture', expected: 'FURNITURE', description: '首字母大写 Furniture' },
    { category: 'wall', expected: 'WALL', description: '小写 wall' },
  ];

  for (const testCase of testCases) {
    console.log(`🔍 测试分类: ${testCase.description}`);

    try {
      const result = await makeRequest(`/rest/v1/equipment?category=${testCase.category}&pageSize=5`);

      if (result.status === 200) {
        console.log(`✅ 请求成功，状态码: ${result.status}`);
        const data = JSON.parse(result.data);
        console.log(`   返回数据条数: ${data.data ? data.data.length : 0}`);
        console.log(`   分页信息: 第${data.pagination?.page}页，共${data.pagination?.total}条`);
      } else if (result.status === 400) {
        console.log(`❌ 请求失败，状态码: ${result.status}`);
        const errorData = JSON.parse(result.data);
        console.log(`   错误信息: ${errorData.message}`);
      } else {
        console.log(`⚠️ 意外状态码: ${result.status}`);
      }
    } catch (error) {
      console.log(`❌ 请求异常: ${error.message}`);
    }

    console.log('');
  }

  console.log('🎯 测试总结:');
  console.log('- 如果所有请求都成功（200），说明大小写转换工作正常');
  console.log('- 如果出现400错误，说明分类验证失败，转换可能有问题');
}

function makeRequest(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          data: data,
          headers: res.headers
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(10000, () => {
      req.abort();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
}

// 运行测试
testCategoryConversion().catch(console.error);