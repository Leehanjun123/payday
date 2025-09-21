import { prisma } from '../lib/prisma';

async function makeAdmin(email: string) {
  try {
    const user = await prisma.user.update({
      where: { email },
      data: { role: 'ADMIN' },
    });

    console.log(`✅ User ${user.email} is now an admin`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Get email from command line argument
const email = process.argv[2];

if (!email) {
  console.error('❌ Please provide an email address');
  console.log('Usage: npx ts-node src/scripts/make-admin.ts <email>');
  process.exit(1);
}

makeAdmin(email);