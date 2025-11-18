const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function addTestExercises() {
  try {
    console.log('正在添加测试练习数据...');

    // 添加一些放松训练的练习数据
    const relaxExercises = await prisma.exercise.createMany({
      data: [
        {
          code: 'deep_breathing_relax',
          name: '深呼吸练习',
          nameEn: 'Deep Breathing Exercise',
          description: '深呼吸有助于放松身心，缓解压力',
          descriptionEn: 'Deep breathing helps relax body and mind, relieving stress',
          duration: 300, // 5分钟
          difficulty: 'GREEN',
          targetMuscles: ['FULL_BODY'],
          intentType: 'RELAX',
          instructions: '坐直，慢慢吸气4秒，屏住4秒，呼气4秒',
          instructionsEn: 'Sit straight, inhale slowly for 4 seconds, hold for 4 seconds, exhale for 4 seconds',
          videoUrl: '/videos/breathing-exercise.mp4',
          thumbnailUrl: '/images/breathing-thumb.jpg',
          isActive: true
        },
        {
          code: 'neck_stretch_relax',
          name: '颈部伸展',
          nameEn: 'Neck Stretch',
          description: '缓解颈部紧张，适合办公室工作者',
          descriptionEn: 'Relieves neck tension, suitable for office workers',
          duration: 180, // 3分钟
          difficulty: 'GREEN',
          targetMuscles: ['FULL_BODY'],
          intentType: 'RELAX',
          instructions: '缓慢左右转动头部，每个方向保持10秒',
          instructionsEn: 'Slowly turn head left and right, hold each direction for 10 seconds',
          videoUrl: '/videos/neck-stretch.mp4',
          thumbnailUrl: '/images/neck-stretch-thumb.jpg',
          isActive: true
        },
        {
          code: 'shoulder_relax',
          name: '肩膀放松',
          nameEn: 'Shoulder Relaxation',
          description: '放松肩膀肌肉，缓解一天的疲劳',
          descriptionEn: 'Relax shoulder muscles, relieve daily fatigue',
          duration: 240, // 4分钟
          difficulty: 'GREEN',
          targetMuscles: ['FULL_BODY'],
          intentType: 'RELAX',
          instructions: '耸肩向上，保持5秒后放松，重复10次',
          instructionsEn: 'Shrug shoulders up, hold for 5 seconds then relax, repeat 10 times',
          videoUrl: '/videos/shoulder-relax.mp4',
          thumbnailUrl: '/images/shoulder-relax-thumb.jpg',
          isActive: true
        }
      ],
      skipDuplicates: true
    });

    console.log(`✅ 成功添加 ${relaxExercises.count} 个练习数据`);

    // 验证数据是否添加成功
    const count = await prisma.exercise.count({
      where: {
        intentType: 'RELAX',
        targetMuscles: {
          has: 'FULL_BODY'
        }
      }
    });

    console.log(`✅ 数据库中现有 ${count} 个匹配条件的练习`);

  } catch (error) {
    console.error('❌ 添加测试数据失败:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

addTestExercises();