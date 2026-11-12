import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Sidebar } from './components/Sidebar';
import { Login } from './pages/Login';
import { Register } from './pages/Register';
import { Dashboard } from './pages/Dashboard';
import { HitlApprovalQueue } from './pages/HitlApprovalQueue';
import { WorkflowInspector } from './pages/WorkflowInspector';
import { Vacancies } from './pages/Vacancies';
import { Companies } from './pages/Companies';
import { InterviewCalendar } from './pages/InterviewCalendar';
import { Reports } from './pages/Reports';
import { ShortlistView } from './pages/ShortlistView';
import { AuditLog } from './pages/AuditLog';
import { CandidateProfile } from './pages/CandidateProfile';
import { CandidateDirectory } from './pages/CandidateDirectory';
import { CandidateVacancies } from './pages/CandidateVacancies';
import { MyApplications } from './pages/MyApplications';
import { User as UserIcon, LogOut, Menu } from 'lucide-react';

interface HeaderBarProps {
  onToggleSidebar: () => void;
}

const HeaderBar: React.FC<HeaderBarProps> = ({ onToggleSidebar }) => {
  const { user, logoutUser } = useAuth();
  if (!user) return null;

  const roleColors: Record<string, string> = {
    Candidate: '#06b6d4',
    Recruiter: '#6366f1',
    Interviewer: '#f59e0b',
    Administrator: '#10b981'
  };

  return (
    <div className="top-header-bar">
      <div className="header-left">
        <button
          className="mobile-menu-toggle"
          onClick={onToggleSidebar}
          type="button"
          aria-label="Toggle navigation menu"
        >
          <Menu size={22} />
        </button>
        <div style={{ background: 'rgba(255,255,255,0.05)', padding: '8px', borderRadius: '50%', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <UserIcon size={18} color={roleColors[user.role] || '#818cf8'} />
        </div>
        <div>
          <div style={{ fontWeight: 700, fontSize: '15px' }}>{user.fullName}</div>
          <div className="header-email" style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{user.email}</div>
        </div>
        <span className="role-pill" style={{ marginLeft: '4px', background: roleColors[user.role] || '#6366f1' }}>
          {user.role}
        </span>
      </div>

      <button onClick={logoutUser} style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: '1px solid rgba(239, 68, 68, 0.3)', padding: '6px 14px', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
        <LogOut size={14} /> <span>Sign Out</span>
      </button>
    </div>
  );
};

// Route Guards based on authentic server user roles
const ProtectedCandidateRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  if (user.role !== 'Candidate') return <Navigate to="/" replace />;
  return <>{children}</>;
};

const ProtectedRecruiterRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  if (user.role === 'Candidate') return <Navigate to="/candidate-profile" replace />;
  return <>{children}</>;
};

const MainLayout: React.FC = () => {
  const { user } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  // Close mobile sidebar on route transition
  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

  if (!user) return <Navigate to="/login" replace />;

  const isCandidate = user.role === 'Candidate';

  return (
    <div className="app-container">
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <main className="main-content">
        <HeaderBar onToggleSidebar={() => setSidebarOpen(prev => !prev)} />
        <Routes key={user.token}>
          {/* Dynamic Landing Route */}
          <Route 
            path="/" 
            element={isCandidate ? <Navigate to="/candidate-profile" replace /> : <Dashboard />} 
          />

          {/* Recruiter / Admin Protected Routes */}
          <Route path="/approval-queue" element={<ProtectedRecruiterRoute><HitlApprovalQueue /></ProtectedRecruiterRoute>} />
          <Route path="/workflow-inspector" element={<WorkflowInspector />} />
          <Route path="/vacancies" element={<ProtectedRecruiterRoute><Vacancies /></ProtectedRecruiterRoute>} />
          <Route path="/companies" element={<ProtectedRecruiterRoute><Companies /></ProtectedRecruiterRoute>} />
          <Route path="/reports" element={<ProtectedRecruiterRoute><Reports /></ProtectedRecruiterRoute>} />
          <Route path="/shortlists" element={<ProtectedRecruiterRoute><ShortlistView /></ProtectedRecruiterRoute>} />
          <Route path="/audit-log" element={<ProtectedRecruiterRoute><AuditLog /></ProtectedRecruiterRoute>} />
          <Route path="/candidates" element={<ProtectedRecruiterRoute><CandidateDirectory /></ProtectedRecruiterRoute>} />

          {/* Candidate Protected Routes */}
          <Route path="/candidate-profile" element={<ProtectedCandidateRoute><CandidateProfile /></ProtectedCandidateRoute>} />
          <Route path="/browse-vacancies" element={<ProtectedCandidateRoute><CandidateVacancies /></ProtectedCandidateRoute>} />
          <Route path="/my-applications" element={<ProtectedCandidateRoute><MyApplications /></ProtectedCandidateRoute>} />

          {/* Shared Routes */}
          <Route path="/interviews" element={<InterviewCalendar />} />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/*" element={<MainLayout />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
};

export default App;
