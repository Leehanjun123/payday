import { prisma } from '../lib/prisma';

// 스킬 기반 챌린지 (도박 아님, 실력 경쟁)
interface SkillChallenge {
  id: string;
  type: 'QUIZ' | 'TYPING_SPEED' | 'MEMORY_GAME' | 'PUZZLE' | 'TRIVIA';
  entryFee: number; // $0.10~1.00 (130~1,300원)
  prizePool: number;
  participants: number;
  maxParticipants: number;
  startTime: Date;
  duration: number; // minutes
  winnerPercentage: number; // 상위 몇%가 상금 획득
}

// 습관 형성 챌린지 (건강한 경쟁)
interface HabitChallenge {
  id: string;
  title: string;
  category: 'FITNESS' | 'STUDY' | 'SAVING' | 'READING' | 'MEDITATION';
  stakingAmount: number; // $1~10 보증금
  duration: number; // days
  successCriteria: string;
  totalParticipants: number;
  successRate: number;
}

class ChallengeService {
  private static instance: ChallengeService;

  static getInstance(): ChallengeService {
    if (!ChallengeService.instance) {
      ChallengeService.instance = new ChallengeService();
    }
    return ChallengeService.instance;
  }

  // 스킬 기반 대회 (e스포츠 형태)
  async joinSkillCompetition(userId: string, challengeId: string): Promise<any> {
    // 퀴즈왕, 타이핑 대회 등
    const competitions = {
      '상식퀴즈_대회': {
        entryFee: 0.10, // $0.10 (130원)
        prizes: {
          '1등': 5.00, // $5 (6,500원)
          '2등': 2.00, // $2 (2,600원)
          '3등': 1.00, // $1 (1,300원)
        },
        platformFee: '20%'
      },
      '스피드_타이핑': {
        entryFee: 0.20,
        prizes: { '상위10%': 2.00 },
        platformFee: '15%'
      }
    };

    return {
      message: '스킬 기반 경쟁 - 실력으로 상금 획득',
      legal: '게임물관리위원회 심의 불필요 (사행성 없음)'
    };
  }

  // 습관 챌린지 (자기계발)
  async createHabitStaking(userId: string, habit: Partial<HabitChallenge>) {
    // 보증금을 걸고 목표 달성
    // 성공 시: 보증금 + 실패자 보증금 일부
    // 실패 시: 보증금 일부 환급

    const examples = {
      '30일_운동': {
        stake: 10.00, // $10 보증금
        successReturn: 15.00, // 성공 시 $15 환급
        failReturn: 5.00, // 실패 시 $5만 환급
      },
      '금연_챌린지': {
        stake: 20.00,
        successReturn: 30.00,
        failReturn: 10.00,
      }
    };

    return {
      type: 'COMMITMENT_DEVICE',
      legal: '도박이 아닌 자기계발 보증금'
    };
  }

  // 지식 공유 배틀
  async knowledgeBattle(userId: string, subject: string, betAmount: number) {
    // 1:1 지식 대결 (체스, 바둑처럼 실력 게임)
    const maxBet = 1.00; // 최대 $1 (1,300원)

    if (betAmount > maxBet) {
      throw new Error('최대 베팅 금액 초과');
    }

    // 승자: 상금의 80%
    // 플랫폼: 20% 수수료

    return {
      winnerTakes: betAmount * 1.8,
      platformFee: betAmount * 0.2
    };
  }
}