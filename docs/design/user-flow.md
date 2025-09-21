# User Flow Design - PayDay

## 1. Core User Flows

### 1.1 Onboarding Flow
```
Start → Splash Screen → Welcome Screen → Sign Up/Login
         ↓                               ↓
    App Tutorial ← Phone Verification ← Email/Social
         ↓
    Profile Setup → Skill Selection → Interest Areas
         ↓
    Notification Permission → Location Permission
         ↓
    Dashboard (Home)
```

### 1.2 Task Discovery Flow
```
Dashboard → Browse Tasks → Filter/Search → Task Details
    ↓           ↓              ↓              ↓
Quick Tasks  Categories    AI Recommend   Apply/Accept
    ↓           ↓              ↓              ↓
             Task List → Task Details → Application
                            ↓
                        Chat with Client
```

### 1.3 Task Execution Flow
```
My Tasks → Active Task → Start Work → Submit Deliverable
    ↓          ↓            ↓              ↓
Calendar   Task Details  Time Track    Upload Files
    ↓          ↓            ↓              ↓
         Requirements    Progress      Review Request
                            ↓
                        Payment Release
```

### 1.4 Payment Flow
```
Task Complete → Review → Payment Request → Processing
      ↓           ↓            ↓              ↓
   Auto-notify  Rating    Bank Transfer   Notification
      ↓           ↓            ↓              ↓
              Feedback    Wallet Update   Tax Invoice
```

## 2. Screen Structure

### 2.1 Main Navigation (Bottom Tab)
1. **홈** - Dashboard, Quick Actions
2. **탐색** - Browse Tasks, Categories
3. **내 작업** - Active, Pending, Completed
4. **수익** - Earnings, Analytics
5. **프로필** - Settings, Level, Achievements

### 2.2 Screen Hierarchy

```
Root
├── Auth
│   ├── Splash
│   ├── Welcome
│   ├── Login
│   ├── SignUp
│   └── Verification
├── Onboarding
│   ├── Tutorial
│   ├── ProfileSetup
│   └── Preferences
└── Main (Tab Navigator)
    ├── Home (Stack)
    │   ├── Dashboard
    │   ├── Notifications
    │   └── QuickTasks
    ├── Explore (Stack)
    │   ├── TaskList
    │   ├── TaskDetail
    │   ├── Categories
    │   └── Search
    ├── MyTasks (Stack)
    │   ├── TaskManager
    │   ├── Calendar
    │   └── TaskProgress
    ├── Earnings (Stack)
    │   ├── Overview
    │   ├── History
    │   ├── Analytics
    │   └── Withdraw
    └── Profile (Stack)
        ├── MyProfile
        ├── Settings
        ├── Achievements
        └── Help
```

## 3. Key Screens Wireframes

### 3.1 Dashboard (Home)
```
┌─────────────────────────┐
│     Good Morning!       │
│     김지현님            │
│   ₩850,000 이번달 수익  │
├─────────────────────────┤
│   🎯 오늘의 미션 (3/5)  │
│   ________________      │
│   ________________      │
├─────────────────────────┤
│   추천 작업             │
│   ┌──────┐ ┌──────┐    │
│   │      │ │      │    │
│   └──────┘ └──────┘    │
├─────────────────────────┤
│   빠른 시작             │
│   [번역] [디자인] [강의]│
└─────────────────────────┘
```

### 3.2 Task Detail
```
┌─────────────────────────┐
│  ← Task Title           │
│                         │
│  Client: ★★★★☆ (4.5)   │
│  Budget: ₩50,000        │
│  Duration: 3 days       │
├─────────────────────────┤
│  Description            │
│  ___________________    │
│  ___________________    │
│  ___________________    │
├─────────────────────────┤
│  Requirements:          │
│  • Point 1              │
│  • Point 2              │
├─────────────────────────┤
│  Similar: 15 people     │
│                         │
│  [    지원하기    ]     │
└─────────────────────────┘
```

### 3.3 Earnings Dashboard
```
┌─────────────────────────┐
│    이번 달 수익         │
│    ₩1,250,000          │
│    ▲ 15% from last     │
├─────────────────────────┤
│    📊 Chart Area        │
│    Weekly/Monthly       │
├─────────────────────────┤
│    Top Categories:      │
│    Design   45%         │
│    Writing  30%         │
│    Teaching 25%         │
├─────────────────────────┤
│    [  출금하기  ]       │
└─────────────────────────┘
```

## 4. Interaction Patterns

### 4.1 Gestures
- **Swipe Right**: Accept/Like
- **Swipe Left**: Reject/Pass
- **Pull to Refresh**: Update content
- **Long Press**: Quick actions menu
- **Pinch**: Zoom in/out (documents)

### 4.2 Animations
- **Page Transitions**: Slide horizontal
- **Modal**: Slide up from bottom
- **Success**: Confetti animation
- **Loading**: Skeleton screens
- **Micro-interactions**: Button press, toggle

### 4.3 Feedback Patterns
- **Visual**: Color changes, icons
- **Haptic**: Success/Error vibration
- **Audio**: Notification sounds
- **Toast**: Brief messages
- **Dialog**: Important confirmations

## 5. User Flow Optimizations

### 5.1 Reducing Friction
- **Auto-save**: Draft applications
- **Quick Apply**: One-tap for similar tasks
- **Smart Filters**: Remember preferences
- **Batch Actions**: Multiple task management
- **Templates**: Reusable proposals

### 5.2 Engagement Triggers
- **Daily Login**: Bonus points
- **Streak System**: Consecutive days
- **Push Notifications**: Smart timing
- **Recommendations**: AI-powered
- **Social Proof**: Success stories

### 5.3 Error Prevention
- **Validation**: Real-time input check
- **Confirmation**: Destructive actions
- **Undo**: Recent actions
- **Recovery**: Auto-save state
- **Help**: Contextual tooltips

## 6. Accessibility

### 6.1 Visual
- High contrast mode
- Font size adjustment
- Color blind friendly
- Clear icons with labels

### 6.2 Motor
- Large touch targets (44x44 minimum)
- Gesture alternatives
- Adjustable timeouts
- Easy navigation

### 6.3 Cognitive
- Simple language
- Clear instructions
- Progress indicators
- Consistent patterns