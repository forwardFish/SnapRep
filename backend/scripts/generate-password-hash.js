const bcrypt = require('bcrypt');

async function generatePasswordHash() {
  const password = 'password123';
  const saltRounds = 10;

  try {
    const hash = await bcrypt.hash(password, saltRounds);
    console.log('Password:', password);
    console.log('Hash:', hash);

    // 验证哈希值是否正确
    const isValid = await bcrypt.compare(password, hash);
    console.log('Verification:', isValid);

    return hash;
  } catch (error) {
    console.error('Error generating hash:', error);
  }
}

generatePasswordHash();