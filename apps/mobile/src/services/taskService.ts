import apiClient from './apiClient';

export interface Task {
  id: string;
  title: string;
  description: string;
  category: string;
  budget: number;
  duration: number;
  status: 'OPEN' | 'IN_PROGRESS' | 'UNDER_REVIEW' | 'COMPLETED' | 'CANCELLED';
  priority: 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';
  deadline?: string;
  createdAt: string;
  poster: {
    id: string;
    name: string;
    profileImage?: string;
    level: number;
  };
  skills?: Array<{
    skill: {
      id: string;
      name: string;
      icon?: string;
    };
  }>;
  _count?: {
    applications: number;
  };
  assignee?: {
    id: string;
    name: string;
    profileImage?: string;
    level: number;
  };
  applications?: TaskApplication[];
}

export interface TaskListResponse {
  tasks: Task[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface TaskFilters {
  category?: string;
  status?: string;
  minBudget?: number;
  maxBudget?: number;
  search?: string;
  page?: number;
  limit?: number;
}

export interface TaskApplication {
  id: string;
  taskId: string;
  userId: string;
  proposal: string;
  bidAmount: number;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'WITHDRAWN';
  appliedAt: string;
  user?: {
    id: string;
    name: string;
    profileImage?: string;
    level: number;
  };
}

class TaskService {
  async getTasks(filters: TaskFilters = {}): Promise<TaskListResponse> {
    const params = new URLSearchParams();

    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== '') {
        params.append(key, String(value));
      }
    });

    const queryString = params.toString();
    const endpoint = `/api/v1/tasks${queryString ? `?${queryString}` : ''}`;

    return apiClient.get<TaskListResponse>(endpoint);
  }

  async getTask(taskId: string): Promise<Task> {
    return apiClient.get<Task>(`/api/v1/tasks/${taskId}`);
  }

  async createTask(taskData: {
    title: string;
    description: string;
    category: string;
    budget: number;
    duration: number;
    priority?: string;
    deadline?: string;
    skillIds?: string[];
  }): Promise<{ message: string; task: Task }> {
    return apiClient.post('/api/v1/tasks', taskData);
  }

  async updateTask(
    taskId: string,
    updates: Partial<{
      title: string;
      description: string;
      category: string;
      budget: number;
      duration: number;
      priority: string;
      deadline: string;
      status: string;
    }>
  ): Promise<{ message: string; task: Task }> {
    return apiClient.put(`/api/v1/tasks/${taskId}`, updates);
  }

  async deleteTask(taskId: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/tasks/${taskId}`);
  }

  async applyToTask(
    taskId: string,
    application: { proposal: string; bidAmount: number }
  ): Promise<{ message: string; application: TaskApplication }> {
    return apiClient.post(`/api/v1/tasks/${taskId}/apply`, application);
  }

  async getMyPostedTasks(): Promise<Task[]> {
    return apiClient.get('/api/v1/tasks/my/posted');
  }

  async getMyAssignedTasks(): Promise<Task[]> {
    return apiClient.get('/api/v1/tasks/my/assigned');
  }
}

export default new TaskService();