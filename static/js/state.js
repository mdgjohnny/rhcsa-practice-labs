/**
 * RHCSA Practice Labs - Global State
 * Shared state variables across all modules
 */

// Task and session state
let allTasks = [];
let selectedTasks = [];
let currentMode = null;
let timerInterval = null;
let examStartTime = null;
let currentTaskIndex = 0;
let taskResults = new Map();
let gradingAborted = false;
let previousView = null;
let cachedConfig = null;
let examDuration = 3 * 60 * 60 * 1000; // Default 3 hours, can be changed for challenges
const SESSION_KEY = 'rhcsa_session';

// Cloud session state
let cloudSession = null;
let sessionMonitorInterval = null;

// Terminal state
let term = null;
let fitAddon = null;
let socket = null;
let currentNode = null;

// Flashcard state
let fcData = null;
let fcProgress = {};
let fcCards = [];
let fcCurrentIndex = 0;
let fcKnown = 0;
let fcUnknown = 0;
let fcMissedCards = [];
let fcSelectedChapters = new Set();
let fcIsFlipped = false;
let fcCardStartTime = null;
let fcStats = null;
let fcStudyMode = 'all';

// Stats state
let currentStatsTab = 'practice';
