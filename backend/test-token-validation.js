const jwt = require('jsonwebtoken');

// 检查 JWT 解析
const JWT_ACCESS_SECRET = 'nestjsPrismaAccessSecret';
const TEST_USER_ID = 'test-user-123';

const payload = {
  userId: TEST_USER_ID,
};

const token = jwt.sign(payload, JWT_ACCESS_SECRET, { expiresIn: '1h' });
console.log('Generated Token:', token);

// 验证 token
try {
  const decoded = jwt.verify(token, JWT_ACCESS_SECRET);
  console.log('Decoded payload:', decoded);
} catch (error) {
  console.error('Token verification failed:', error.message);
}

// 生成一个真实的用户 token（需要一个真实的用户ID）
// 你需要从数据库中找一个真实的用户ID
const realUserId = 'ecac45ff-1c2c-4937-bb67-ac7f0b0d2cab'; // 替换为真实用户ID
const realPayload = {
  userId: realUserId,
};

const realToken = jwt.sign(realPayload, JWT_ACCESS_SECRET, { expiresIn: '1h' });
console.log('\nReal User Token:', realToken);

// 验证真实用户 token
try {
  const decodedReal = jwt.verify(realToken, JWT_ACCESS_SECRET);
  console.log('Decoded real payload:', decodedReal);
} catch (error) {
  console.error('Real token verification failed:', error.message);
}