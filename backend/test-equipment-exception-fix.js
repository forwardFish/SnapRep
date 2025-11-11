const http = require('http');

async function testEquipmentAlreadyExists() {
  console.log('🧪 测试 EQUIPMENT_ALREADY_EXISTS 异常处理修复...\n');

  // 等待服务启动
  console.log('⏳ 等待服务启动...');
  await new Promise(resolve => setTimeout(resolve, 3000));

  const testData = {
    code: 'TEST_DUPLICATE_CODE',
    name: '测试器材',
    category: '测试分类',
    imageUrl: 'https://example.com/test.jpg',
    displayOrder: 1,
    isActive: true
  };

  console.log('🔧 第一次创建器材（应该成功）...');
  let firstResult = await createEquipment(testData);

  if (firstResult.success) {
    console.log('✅ 第一次创建成功');

    console.log('🔧 第二次创建相同代码的器材（应该返回正确的 code=8001 冲突错误）...');
    let secondResult = await createEquipment(testData);

    if (!secondResult.success && secondResult.error) {
      console.log('📊 错误响应分析:');
      console.log(`错误代码: ${secondResult.error.code}`);
      console.log(`错误消息: ${secondResult.error.message}`);
      console.log(`错误类别: ${secondResult.error.category}`);
      console.log(`HTTP状态码: ${secondResult.statusCode}`);

      if (secondResult.error.code === 8001) {
        console.log('🎉 修复成功！返回了正确的业务错误代码 8001 (EQUIPMENT_ALREADY_EXISTS)');
        console.log('✅ 业务异常正确透传，没有被全局过滤器改写为 1004');
      } else if (secondResult.error.code === 1004) {
        console.log('❌ 修复失败！仍然返回系统错误代码 1004');
        console.log('⚠️ ResponseError 仍被 GlobalExceptionFilter 错误处理');
      } else {
        console.log(`🤔 返回了意外的错误代码: ${secondResult.error.code}`);
      }
    } else {
      console.log('❌ 预期应该返回冲突错误，但没有');
    }
  } else {
    console.log('❌ 第一次创建失败，无法继续测试');
    console.log('错误:', firstResult);
  }
}

async function createEquipment(data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);

    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/rest/v1/equipment',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve({
            success: res.statusCode >= 200 && res.statusCode < 300,
            statusCode: res.statusCode,
            ...response
          });
        } catch (e) {
          resolve({
            success: false,
            statusCode: res.statusCode,
            rawData: data
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.setTimeout(5000, () => {
      req.abort();
      reject(new Error('Request timeout'));
    });

    req.write(postData);
    req.end();
  });
}

// 运行测试
testEquipmentAlreadyExists().catch(console.error);