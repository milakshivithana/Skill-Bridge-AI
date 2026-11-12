import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type RecruitmentAnalytics } from '../services/api';
import { Briefcase, Users, CheckCircle, Clock, Sparkles } from 'lucide-react';

export const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? '';
  const [analytics, setAnalytics] = useState<RecruitmentAnalytics | null>(null);

  useEffect(() => {
    api.getAnalytics(token).then(setAnalytics);
  }, [token]);

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>Recruitment Dashboard</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            SkillBridge AI - Intelligent Internship & Recruitment Coordination Platform
          </p>
        </div>

        <div className="user-badge">
          <span style={{ fontSize: '14px', fontWeight: 600 }}>Sarah Jenkins</span>
          <span className="role-pill">Recruiter</span>
        </div>
      </div>

      <div className="grid-metrics">
        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)' }}>
            <span>Active Vacancies</span>
            <Briefcase size={20} color="#6366f1" />
          </div>
          <div className="metric-value">{analytics?.totalVacancies || 12}</div>
        </div>

        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)' }}>
            <span>Total Applications</span>
            <Users size={20} color="#06b6d4" />
          </div>
          <div className="metric-value">{analytics?.totalApplications || 48}</div>
        </div>

        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)' }}>
            <span>HITL AI Pending Queue</span>
            <Clock size={20} color="#f59e0b" />
          </div>
          <div className="metric-value">{analytics?.pendingApprovals || 6}</div>
        </div>

        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)' }}>
            <span>Average Match Score</span>
            <Sparkles size={20} color="#10b981" />
          </div>
          <div className="metric-value">{analytics?.averageMatchScore || 84.5}%</div>
        </div>
      </div>

      <div className="glass-panel" style={{ padding: '24px' }}>
        <h2 style={{ fontSize: '20px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <CheckCircle size={22} color="#10b981" />
          <span>Recent AI Workflow Evaluations</span>
        </h2>

        <table className="table-custom">
          <thead>
            <tr>
              <th>Candidate</th>
              <th>Vacancy</th>
              <th>Match Score</th>
              <th>Validation</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>
                <div style={{ fontWeight: 600 }}>Candidate 102</div>
                <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>candidate102@student.sliit.lk</div>
              </td>
              <td>Software Engineering Intern</td>
              <td>
                <span style={{ fontWeight: 700, color: '#10b981' }}>84.0%</span>
              </td>
              <td>
                <span style={{ color: '#10b981', fontWeight: 600 }}>PASSED</span>
              </td>
              <td>
                <span className="status-badge status-pending">PENDING RECRUITER APPROVAL</span>
              </td>
            </tr>
            <tr>
              <td>
                <div style={{ fontWeight: 600 }}>Candidate 105</div>
                <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>candidate105@student.sliit.lk</div>
              </td>
              <td>AI & Machine Learning Trainee</td>
              <td>
                <span style={{ fontWeight: 700, color: '#10b981' }}>92.0%</span>
              </td>
              <td>
                <span style={{ color: '#10b981', fontWeight: 600 }}>PASSED</span>
              </td>
              <td>
                <span className="status-badge status-approved">APPROVED</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
};
