const { PrismaClient } = require('@prisma/client');

try {
  const prisma = new PrismaClient();
  const models = Object.keys(prisma).filter(k => !k.startsWith('_') && k !== 'dmmf');
  console.log('✅ Prisma Client loaded successfully');
  console.log('📊 Available models:', models);
  console.log('🔢 Model count:', models.length);

  // Check for specific models that tests are expecting
  const expectedModels = ['user', 'scenario', 'equipment', 'exercise', 'workoutSession', 'shareCard'];
  console.log('\n🔍 Expected models check:');
  expectedModels.forEach(model => {
    const exists = models.includes(model);
    console.log(`   ${exists ? '✅' : '❌'} ${model}: ${exists ? 'Found' : 'Missing'}`);
  });

} catch (error) {
  console.error('❌ Prisma Client Error:', error.message);
  if (error.message.includes('generated')) {
    console.log('💡 Suggestion: Run `npx prisma generate` to generate the client');
  }
}