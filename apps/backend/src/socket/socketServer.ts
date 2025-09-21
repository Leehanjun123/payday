import { Server } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

interface SocketUser {
  id: string;
  socketId: string;
  userId: string;
}

const activeUsers = new Map<string, SocketUser>();

export function initializeSocket(httpServer: HttpServer) {
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication failed'));
      }

      const decoded = jwt.verify(token, JWT_SECRET) as { userId: string };
      socket.data.userId = decoded.userId;
      next();
    } catch (error) {
      next(new Error('Authentication failed'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`User connected: ${socket.data.userId}`);

    // Store active user
    activeUsers.set(socket.data.userId, {
      id: socket.id,
      socketId: socket.id,
      userId: socket.data.userId,
    });

    // Join user's personal room
    socket.join(`user:${socket.data.userId}`);

    // Get user's chat rooms
    const userRooms = await prisma.chatParticipant.findMany({
      where: { userId: socket.data.userId },
      include: { room: true },
    });

    // Join all chat rooms
    for (const participant of userRooms) {
      socket.join(`room:${participant.roomId}`);
    }

    // Handle joining a chat room
    socket.on('join_room', async (data: { taskId: string }) => {
      try {
        const { taskId } = data;

        // Check if user is authorized to join this chat
        const task = await prisma.task.findUnique({
          where: { id: taskId },
        });

        if (!task) {
          socket.emit('error', { message: 'Task not found' });
          return;
        }

        const isAuthorized =
          task.posterId === socket.data.userId ||
          task.assigneeId === socket.data.userId;

        if (!isAuthorized) {
          socket.emit('error', { message: 'Unauthorized to join this chat' });
          return;
        }

        // Create or get chat room
        let chatRoom = await prisma.chatRoom.findUnique({
          where: { taskId },
          include: {
            participants: true,
            messages: {
              take: 50,
              orderBy: { createdAt: 'desc' },
              include: {
                sender: {
                  select: { id: true, name: true, profileImage: true },
                },
                readBy: true,
              },
            },
          },
        });

        if (!chatRoom) {
          // Create new chat room
          chatRoom = await prisma.chatRoom.create({
            data: {
              taskId,
              participants: {
                create: [
                  { userId: task.posterId },
                  ...(task.assigneeId ? [{ userId: task.assigneeId }] : []),
                ],
              },
            },
            include: {
              participants: true,
              messages: true,
            },
          });
        }

        // Join socket room
        socket.join(`room:${chatRoom.id}`);

        // Send chat history
        socket.emit('room_joined', {
          roomId: chatRoom.id,
          messages: chatRoom.messages.reverse(),
        });
      } catch (error) {
        console.error('Error joining room:', error);
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    // Handle sending messages
    socket.on(
      'send_message',
      async (data: { roomId: string; content: string }) => {
        try {
          const { roomId, content } = data;

          // Verify user is participant
          const participant = await prisma.chatParticipant.findUnique({
            where: {
              roomId_userId: {
                roomId,
                userId: socket.data.userId,
              },
            },
          });

          if (!participant) {
            socket.emit('error', { message: 'Unauthorized to send message' });
            return;
          }

          // Create message
          const message = await prisma.message.create({
            data: {
              content,
              roomId,
              senderId: socket.data.userId,
            },
            include: {
              sender: {
                select: { id: true, name: true, profileImage: true },
              },
              readBy: true,
            },
          });

          // Update participant's last read
          await prisma.chatParticipant.update({
            where: {
              roomId_userId: {
                roomId,
                userId: socket.data.userId,
              },
            },
            data: {
              lastReadAt: new Date(),
            },
          });

          // Send message to room
          io.to(`room:${roomId}`).emit('new_message', message);

          // Send push notification to offline users
          const otherParticipants = await prisma.chatParticipant.findMany({
            where: {
              roomId,
              userId: { not: socket.data.userId },
            },
            include: {
              user: true,
            },
          });

          for (const participant of otherParticipants) {
            if (!activeUsers.has(participant.userId)) {
              // User is offline, send push notification
              await sendPushNotification(participant.userId, {
                title: 'New Message',
                body: `${message.sender.name}: ${content}`,
                data: { roomId, type: 'new_message' },
              });
            }
          }
        } catch (error) {
          console.error('Error sending message:', error);
          socket.emit('error', { message: 'Failed to send message' });
        }
      }
    );

    // Handle typing indicators
    socket.on('typing', async (data: { roomId: string; isTyping: boolean }) => {
      socket.to(`room:${data.roomId}`).emit('user_typing', {
        userId: socket.data.userId,
        isTyping: data.isTyping,
      });
    });

    // Handle marking messages as read
    socket.on('mark_read', async (data: { messageId: string }) => {
      try {
        await prisma.messageRead.create({
          data: {
            messageId: data.messageId,
            userId: socket.data.userId,
          },
        });

        socket.to(`room:${data.messageId}`).emit('message_read', {
          messageId: data.messageId,
          userId: socket.data.userId,
        });
      } catch (error) {
        // Already marked as read
      }
    });

    // Handle disconnect
    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.data.userId}`);
      activeUsers.delete(socket.data.userId);
    });
  });

  return io;
}

async function sendPushNotification(
  userId: string,
  notification: { title: string; body: string; data: any }
) {
  // This would integrate with your push notification service
  // For now, we'll just create a database notification
  await prisma.notification.create({
    data: {
      userId,
      type: 'SYSTEM',
      title: notification.title,
      message: notification.body,
      data: notification.data,
    },
  });
}