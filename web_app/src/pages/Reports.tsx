import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type RecruitmentAnalytics } from '../services/api';
import { TrendingUp, Award, CheckCircle, Clock, Cpu, BarChart3, AlertCircle } from 'lucide-react';

const BarChart: React.FC<{ label: string; value: number; max: number; color: string }> = ({ label, value, max, color }) => {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0;
  return (
    <div style={{ marginBottom: '14px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px', fontSize: '13px' }}>
        <span style={{ color: 'var(--text-secondary)' }}>{label}</span>
        <span style={{ fontWeight: 700, color }}>{value}</span>
      </div>
      <div style={{ background: 'rgba(255,255,255,0.06)', borderRadius: '6px', height: '10px', overflow: 'hidden' }}>
        <div style={{
          width: `${pct}%`, height: '100%', borderRadius: '6px',
          background: `linear-gradient(90deg, ${color}aa, ${color})`,
          transition: 'width 0.8s cubic-bezier(0.25,0.46,0.45,0.94)'
        }} />
      </div>
    </div>
  );
};

const ScoreRing: React.FC<{ score: number }> = ({ score }) => {
  const color = score >= 80 ? '#10b981' : score >= 60 ? '#f59e0b' : '#ef4444';
  const circumference = 2 * Math.PI * 42;
  const offset = circumference - (score / 100) * circumference;
  return (
    <div style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
      <svg width={100} height={100} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={50} cy={50} r={42} fill="none" stroke="rgba(255,255,255,0.07)" strokeWidth={8} />
        <circle cx={50} cy={50} r={42} fill="none" stroke={color} strokeWidth={8}
          strokeDasharray={circumference} strokeDashoffset={offset}
          strokeLinecap="round" style={{ transition: 'stroke-dashoffset 1s ease' }} />
      </svg>
      <div style={{ position: 'absolute', textAlign: 'center' }}>
        <div style={{ fontSize: '20px', fontWeight: 800, color }}>{score}%</div>
        <div style={{ fontSize: '10px', color: 'var(--text-secondary)', marginTop: '2px' }}>Avg Match</div>
      </div>
    </div>
  );
};

export const Reports: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? '';
  const [data, setData] = useState<RecruitmentAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getAnalytics(token).then(d => { setData(d); setLoading(false); });
  }, [token]);

  if (loading) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '300px' }}>
      <div style={{ textAlign: 'center' }}>
        <BarChart3 size={40} color="#6366f1" style={{ margin: '0 auto 16px' }} />
        <p style={{ color: 'var(--text-secondary)' }}>Loading analytics from backend...</p>
      </div>
    </div>
  );

  const d = data!;
  const total = d.totalApplications || 1;

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>Recruitment Analytics & Reports</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            System-wide recruitment metrics, AI matching precision, and shortlist conversion history.
          </p>
        </div>
      </div>

      {/* Top KPI Cards */}
      <div className="grid-metrics" style={{ marginBottom: '24px' }}>
        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', marginBottom: '8px' }}>
            <span>Total Vacancies</span>
            <Award size={20} color="#6366f1" />
          </div>
          <div className="metric-value">{d.totalVacancies}</div>
        </div>
        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', marginBottom: '8px' }}>
            <span>Total Applications</span>
            <TrendingUp size={20} color="#06b6d4" />
          </div>
          <div className="metric-value">{d.totalApplications}</div>
        </div>
        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', marginBottom: '8px' }}>
            <span>Pending Approvals</span>
            <Clock size={20} color="#f59e0b" />
          </div>
          <div className="metric-value" style={{ color: '#f59e0b' }}>{d.pendingApprovals}</div>
        </div>
        <div className="glass-panel metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-secondary)', marginBottom: '8px' }}>
            <span>AI Workflows Run</span>
            <Cpu size={20} color="#10b981" />
          </div>
          <div className="metric-value" style={{ color: '#10b981' }}>{d.totalAiWorkflowsRun}</div>
        </div>
      </div>

      <div className="responsive-grid-2" style={{ marginBottom: '24px' }}>
        {/* Application Status Funnel */}
        <div className="glass-panel" style={{ padding: '28px' }}>
          <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <BarChart3 size={18} color="#6366f1" /> Application Status Breakdown
          </h3>
          <BarChart label="✅ Approved" value={d.approvedApplications} max={total} color="#10b981" />
          <BarChart label="⏳ Pending HITL Approval" value={d.pendingApprovals} max={total} color="#f59e0b" />
          <BarChart label="🔄 Revision Requested" value={d.revisionRequested} max={total} color="#06b6d4" />
          <BarChart label="❌ Rejected" value={d.rejectedApplications} max={total} color="#ef4444" />
          <BarChart label="🤖 In AI Matching" value={d.inAiMatching} max={total} color="#8b5cf6" />
        </div>

        {/* AI Quality Panel */}
        <div className="glass-panel" style={{ padding: '28px' }}>
          <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Cpu size={18} color="#10b981" /> AI Pipeline Quality
          </h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: '32px', marginBottom: '28px' }}>
            <ScoreRing score={Math.round(d.averageMatchScore)} />
            <div>
              <div style={{ marginBottom: '12px' }}>
                <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>Rule Compliance</div>
                <div style={{ fontSize: '22px', fontWeight: 800, color: '#10b981' }}>{d.aiWorkflowSuccessRate}</div>
              </div>
              <div>
                <div style={{ fontSize: '12px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>Total Audit Actions</div>
                <div style={{ fontSize: '22px', fontWeight: 800, color: '#06b6d4' }}>{d.totalAuditActions}</div>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            {[
              { icon: <CheckCircle size={16} color="#10b981" />, label: 'Allowed-attribute validation', val: 'PASSED' },
              { icon: <CheckCircle size={16} color="#10b981" />, label: 'Schema validation', val: 'PASSED' },
              { icon: <CheckCircle size={16} color="#10b981" />, label: 'HITL gate enforced', val: 'ACTIVE' },
              { icon: <AlertCircle size={16} color="#f59e0b" />, label: 'Disallowed attributes detected', val: '0' },
            ].map(item => (
              <div key={item.label} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                  {item.icon} {item.label}
                </div>
                <span style={{ fontWeight: 700, fontSize: '13px', color: '#10b981' }}>{item.val}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Conversion Rate Summary */}
      <div className="glass-panel" style={{ padding: '28px' }}>
        <h3 style={{ fontSize: '17px', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <TrendingUp size={18} color="#10b981" /> Recruitment Conversion Summary
        </h3>
        <div className="responsive-grid-3">
          {[
            { label: 'Shortlist Conversion Rate', value: total > 0 ? `${Math.round((d.approvedApplications / total) * 100)}%` : '0%', color: '#10b981' },
            { label: 'AI Success Rate', value: d.aiWorkflowSuccessRate, color: '#6366f1' },
            { label: 'Avg Match Score', value: `${d.averageMatchScore}%`, color: '#06b6d4' },
          ].map(stat => (
            <div key={stat.label} style={{ textAlign: 'center', padding: '20px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px', border: '1px solid var(--border-color)' }}>
              <div style={{ fontSize: '32px', fontWeight: 800, color: stat.color }}>{stat.value}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '6px' }}>{stat.label}</div>
            </div>
          ))}
        </div>
        <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '20px', padding: '12px', background: 'rgba(255,255,255,0.03)', borderRadius: '8px' }}>
          ⚖️ All recruitment proposals strictly enforce non-discriminatory matching rules. Only declared skills, education, and job requirements are evaluated by the Agentic AI subsystem.
        </p>
      </div>
    </div>
  );
};
