import { prisma } from '../lib/prisma';

async function seedSkills() {
  try {
    const initialSkills = [
      // 디자인
      { name: '로고 디자인', category: '디자인', icon: '🎨' },
      { name: '웹 디자인', category: '디자인', icon: '🌐' },
      { name: '앱 디자인', category: '디자인', icon: '📱' },
      { name: 'UI/UX 디자인', category: '디자인', icon: '✏️' },
      { name: '포스터 디자인', category: '디자인', icon: '🖼️' },
      { name: '일러스트', category: '디자인', icon: '🎭' },

      // 개발
      { name: '웹 개발', category: '개발', icon: '💻' },
      { name: '앱 개발', category: '개발', icon: '📱' },
      { name: 'React', category: '개발', icon: '⚛️' },
      { name: 'Node.js', category: '개발', icon: '🟢' },
      { name: 'Python', category: '개발', icon: '🐍' },
      { name: 'Java', category: '개발', icon: '☕' },

      // 번역
      { name: '영한 번역', category: '번역', icon: '🇺🇸' },
      { name: '한영 번역', category: '번역', icon: '🇰🇷' },
      { name: '일한 번역', category: '번역', icon: '🇯🇵' },
      { name: '중한 번역', category: '번역', icon: '🇨🇳' },

      // 마케팅
      { name: 'SNS 마케팅', category: '마케팅', icon: '📢' },
      { name: '콘텐츠 마케팅', category: '마케팅', icon: '📝' },
      { name: '인플루언서 마케팅', category: '마케팅', icon: '🌟' },
      { name: 'SEO', category: '마케팅', icon: '🔍' },

      // 교육
      { name: '영어 과외', category: '교육', icon: '📚' },
      { name: '수학 과외', category: '교육', icon: '🔢' },
      { name: '프로그래밍 강의', category: '교육', icon: '👨‍💻' },
      { name: '음악 레슨', category: '교육', icon: '🎵' },

      // 영상
      { name: '영상 편집', category: '영상', icon: '🎬' },
      { name: '영상 촬영', category: '영상', icon: '📹' },
      { name: '모션 그래픽', category: '영상', icon: '🎞️' },
      { name: '자막 제작', category: '영상', icon: '💬' },

      // 글쓰기
      { name: '블로그 글쓰기', category: '글쓰기', icon: '✍️' },
      { name: '카피라이팅', category: '글쓰기', icon: '📝' },
      { name: '보도자료 작성', category: '글쓰기', icon: '📰' },
      { name: '제품 설명 작성', category: '글쓰기', icon: '📋' },
    ];

    let count = 0;
    for (const skill of initialSkills) {
      try {
        await prisma.skill.create({
          data: skill,
        });
        count++;
      } catch (error: any) {
        if (error.code === 'P2002') {
          console.log(`⚠️  Skill "${skill.name}" already exists, skipping...`);
        } else {
          throw error;
        }
      }
    }

    console.log(`✅ ${count} skills created successfully`);

    // Show all skills
    const allSkills = await prisma.skill.findMany({
      orderBy: [
        { category: 'asc' },
        { name: 'asc' },
      ],
    });

    console.log('\n📋 All skills:');
    let currentCategory = '';
    allSkills.forEach(skill => {
      if (skill.category !== currentCategory) {
        currentCategory = skill.category;
        console.log(`\n${currentCategory}:`);
      }
      console.log(`  ${skill.icon} ${skill.name}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

seedSkills();