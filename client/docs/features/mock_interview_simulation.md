# Mock Interview Simulation

A React-based application that simulates AI-powered technical interviews for data science, data analysis, and machine learning engineering roles.

## Features

- **Multi-step interview process**: Setup, Preparation, Interview, and Results
- **Customizable interview settings**: Difficulty level, duration, question types
- **AI voice simulation**: Visual audio waveform with playback controls
- **Response word counter**: Enforces 200-500 word limits
- **Video recording capabilities**: For post-interview review
- **Detailed AI analysis**: Performance breakdowns and improvement suggestions

## Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
npm install lucide-react
```
3. Add the component to your project

## Usage

### Setup the component

```jsx
import MockInterviewSimulation from './components/MockInterviewSimulation';

function App() {
  return (
    <div className="App">
      <MockInterviewSimulation />
    </div>
  );
}
```

### Tailwind CSS configuration

This component requires Tailwind CSS. Install and configure it:

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

Update your `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

## Component Structure

```
MockInterviewSimulation
├── Setup Screen
│   ├── Interview Type Selection
│   ├── Interview Settings
│   └── Question Categories
├── Preparation Screen
│   ├── Camera & Microphone Setup
│   └── Interview Tips
├── Interview Screen
│   ├── Question Display
│   ├── AI Voice Visualization
│   ├── Response Input Box
│   └── Video Recording
└── Results Screen
    ├── Strengths Analysis
    ├── Areas for Improvement
    └── Performance Metrics
```

## Screen Descriptions

### Setup Screen
Allows users to select interview type (Data Science, Data Analyst, ML Engineer), set difficulty level, duration, response time, and choose question categories.

### Preparation Screen
Provides camera and microphone setup, interview tips for technical and behavioral questions.

### Interview Screen
Displays questions with AI voice visualization, provides a response input box with word counter (200-500 word limit), and includes video recording capabilities.

### Results Screen
Shows AI analysis of interview performance, including strengths, areas for improvement, and performance metrics.

## Development Notes

- Built with React and Tailwind CSS
- Uses Lucide React for icons
- Implements responsive design for various screen sizes
- Features state management for multi-step interview process