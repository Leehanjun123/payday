import express, { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import { authenticate, authorize, AuthRequest } from '../middleware/auth';

const router = express.Router();

// Get all skills
router.get('/', async (req: Request, res: Response) => {
  try {
    const { category } = req.query;

    const where = category ? { category: category as string } : {};

    const skills = await prisma.skill.findMany({
      where,
      orderBy: [
        { category: 'asc' },
        { name: 'asc' },
      ],
      include: {
        _count: {
          select: {
            users: true,
            tasks: true,
          },
        },
      },
    });

    // Group skills by category
    const groupedSkills = skills.reduce((acc, skill) => {
      if (!acc[skill.category]) {
        acc[skill.category] = [];
      }
      acc[skill.category].push(skill);
      return acc;
    }, {} as Record<string, typeof skills>);

    res.json({
      skills,
      grouped: groupedSkills,
      categories: Object.keys(groupedSkills),
    });
  } catch (error) {
    console.error('Error fetching skills:', error);
    res.status(500).json({
      error: 'Failed to fetch skills',
    });
  }
});

// Create new skill (admin only)
router.post('/', authenticate, authorize('ADMIN'), async (req: AuthRequest, res: Response) => {
  try {
    const { name, category, icon, description } = req.body;

    if (!name || !category) {
      return res.status(400).json({
        error: 'Name and category are required',
      });
    }

    // Check if skill already exists
    const existingSkill = await prisma.skill.findUnique({
      where: { name },
    });

    if (existingSkill) {
      return res.status(409).json({
        error: 'Skill already exists',
      });
    }

    const skill = await prisma.skill.create({
      data: {
        name,
        category,
        icon,
        description,
      },
    });

    res.status(201).json({
      message: 'Skill created successfully',
      skill,
    });
  } catch (error) {
    console.error('Error creating skill:', error);
    res.status(500).json({
      error: 'Failed to create skill',
    });
  }
});

// Update skill (admin only)
router.put('/:skillId', authenticate, authorize('ADMIN'), async (req: AuthRequest, res: Response) => {
  try {
    const { skillId } = req.params;
    const { name, category, icon, description } = req.body;

    const skill = await prisma.skill.update({
      where: { id: skillId },
      data: {
        ...(name && { name }),
        ...(category && { category }),
        ...(icon !== undefined && { icon }),
        ...(description !== undefined && { description }),
      },
    });

    res.json({
      message: 'Skill updated successfully',
      skill,
    });
  } catch (error) {
    console.error('Error updating skill:', error);
    res.status(500).json({
      error: 'Failed to update skill',
    });
  }
});

// Delete skill (admin only)
router.delete('/:skillId', authenticate, authorize('ADMIN'), async (req: AuthRequest, res: Response) => {
  try {
    const { skillId } = req.params;

    // Check if skill is in use
    const skillInUse = await prisma.userSkill.findFirst({
      where: { skillId },
    });

    if (skillInUse) {
      return res.status(400).json({
        error: 'Cannot delete skill that is in use',
      });
    }

    await prisma.skill.delete({
      where: { id: skillId },
    });

    res.json({
      message: 'Skill deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting skill:', error);
    res.status(500).json({
      error: 'Failed to delete skill',
    });
  }
});

// Get popular skills
router.get('/popular', async (req: Request, res: Response) => {
  try {
    const skills = await prisma.skill.findMany({
      include: {
        _count: {
          select: {
            users: true,
            tasks: true,
          },
        },
      },
      orderBy: {
        users: {
          _count: 'desc',
        },
      },
      take: 20,
    });

    res.json(skills);
  } catch (error) {
    console.error('Error fetching popular skills:', error);
    res.status(500).json({
      error: 'Failed to fetch popular skills',
    });
  }
});

// Seed initial skills
router.post('/seed', authenticate, authorize('ADMIN'), async (req: AuthRequest, res: Response) => {
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

    const skills = await prisma.skill.createMany({
      data: initialSkills
    });

    res.json({
      message: `${skills.count} skills created successfully`,
    });
  } catch (error) {
    console.error('Error seeding skills:', error);
    res.status(500).json({
      error: 'Failed to seed skills',
    });
  }
});

export default router;