import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { LayoutDashboard, CheckSquare, Briefcase, Cpu, Calendar, BarChart3, User, Send, LogOut, ListOrdered, Shield, X, Users } from 'lucide-react';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen = false, onClose }) => {
  const { user, logoutUser } = useAuth();

  if (!user) return null;

  const isCandidate = user.role === 'Candidate';
  const isInterviewer = user.role === 'Interviewer';

  const handleLinkClick = () => {
    if (onClose) onClose();
  };

  return (
    <>
      {/* Mobile Drawer Backdrop */}
      <div 
        className={`sidebar-overlay ${isOpen ? 'active' : ''}`} 
        onClick={onClose} 
        aria-hidden="true" 
      />

      <aside className={`sidebar ${isOpen ? 'open' : ''}`}>
        <div className="brand-logo-container">
          <div className="brand-logo">
            <Cpu size={28} color="#6366f1" />
            <span>SkillBridge AI</span>
          </div>
          {onClose && (
            <button 
              className="sidebar-close-btn" 
              onClick={onClose} 
              aria-label="Close sidebar menu"
              type="button"
            >
              <X size={20} />
            </button>
          )}
        </div>

      <ul className="nav-links">
        {isCandidate && (
          <>
            <li className="nav-item">
              <NavLink to="/candidate-profile" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <User size={20} />
                <span>My Profile & Skills</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/browse-vacancies" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Briefcase size={20} />
                <span>Browse Vacancies</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/my-applications" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Send size={20} />
                <span>My Applications</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/interviews" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Calendar size={20} />
                <span>Interview Invitations</span>
              </NavLink>
            </li>
          </>
        )}

        {isInterviewer && (
          <>
            <li className="nav-item">
              <NavLink to="/interviews" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Calendar size={20} />
                <span>My Assigned Interviews</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/workflow-inspector" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Cpu size={20} />
                <span>AI Candidate Audit</span>
              </NavLink>
            </li>
          </>
        )}

        {!isCandidate && !isInterviewer && (
          <>
            <li className="nav-item">
              <NavLink to="/" end onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <LayoutDashboard size={20} />
                <span>Dashboard</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/approval-queue" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <CheckSquare size={20} />
                <span>HITL AI Approvals</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/shortlists" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <ListOrdered size={20} />
                <span>Shortlists</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/vacancies" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Briefcase size={20} />
                <span>Vacancies</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/companies" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Briefcase size={20} />
                <span>Companies</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/candidates" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Users size={20} />
                <span>Candidate Directory</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/workflow-inspector" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Cpu size={20} />
                <span>Agentic AI Audit</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/interviews" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Calendar size={20} />
                <span>Interviews</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/reports" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <BarChart3 size={20} />
                <span>Reports & Analytics</span>
              </NavLink>
            </li>
            <li className="nav-item">
              <NavLink to="/audit-log" onClick={handleLinkClick} className={({ isActive }) => (isActive ? 'active' : '')}>
                <Shield size={20} />
                <span>Audit Log</span>
              </NavLink>
            </li>
          </>
        )}
      </ul>

      <div style={{ marginTop: 'auto', paddingTop: '20px', borderTop: '1px solid var(--border-color)' }}>
        <button onClick={logoutUser} style={{ width: '100%', padding: '10px', borderRadius: '8px', background: 'rgba(239, 68, 68, 0.15)', color: '#ef4444', border: '1px solid rgba(239, 68, 68, 0.3)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', fontWeight: 600 }}>
          <LogOut size={16} /> Sign Out
        </button>
      </div>
    </aside>
  </>
  );
};
