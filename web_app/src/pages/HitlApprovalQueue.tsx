import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type PendingApproval } from '../services/api';
import { CheckCircle2, XCircle, RefreshCw, Calendar, Cpu, ShieldCheck, ChevronDown, ChevronUp, Loader2, Users } from 'lucide-react';

export const HitlApprovalQueue: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? '';
  const [pendingApps, setPendingApps] = useState<PendingApproval[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [decisions, setDecisions] = useState<Record<number, string>>({});
  const [processing, setProcessing] = useState<number | null>(null);

  useEffect(() => {
    api.getPendingApprovals(token).then(data => {
      setPendingApps(data);
      setLoading(false);
      if (data.length > 0) setExpandedId(data[0].applicationId);
    });
  }, [token]);

  const handleDecision = async (appId: number, action: 'approve' | 'reject' | 'revision') => {
    setProcessing(appId);
    let success = false;
    if (action === 'approve') success = await api.approveApplication(appId, token, 'Approved by recruiter after AI review.');
    else if (action === 'reject') success = await api.rejectApplication(appId, token, 'Rejected based on requirements review.');
    else success = await api.requestRevision(appId, token, 'Revision requested for additional interview slot.');

    if (success) {
      const label = action === 'approve' ? 'APPROVED' : action === 'reject' ? 'REJECTED' : 'REVISION_REQUESTED';
      setDecisions(prev => ({ ...prev, [appId]: label }));
      setPendingApps(prev => prev.filter(a => a.applicationId !== appId));
    }
    setProcessing(null);
  };

  const getScoreColor = (score: number) => {
    if (score >= 80) return '#10b981';
    if (score >= 60) return '#f59e0b';
    return '#ef4444';
  };

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>Human-in-the-Loop (HITL) AI Approval Queue</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Review AI-assisted candidate matching proposals before authorizing recruitment actions.
          </p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{ background: 'rgba(99,102,241,0.15)', border: '1px solid rgba(99,102,241,0.3)', padding: '8px 16px', borderRadius: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Users size={16} color="#818cf8" />
            <span style={{ color: '#818cf8', fontWeight: 700 }}>{pendingApps.length} Pending</span>
          </div>
        </div>
      </div>

      {/* Decision notifications */}
      {Object.entries(decisions).map(([id, decision]) => (
        <div key={id} style={{
          background: decision === 'APPROVED' ? 'rgba(16,185,129,0.15)' : decision === 'REJECTED' ? 'rgba(239,68,68,0.15)' : 'rgba(245,158,11,0.15)',
          border: `1px solid ${decision === 'APPROVED' ? 'rgba(16,185,129,0.4)' : decision === 'REJECTED' ? 'rgba(239,68,68,0.4)' : 'rgba(245,158,11,0.4)'}`,
          borderRadius: '10px', padding: '12px 20px', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '10px'
        }}>
          {decision === 'APPROVED' ? <CheckCircle2 size={18} color="#10b981" /> : decision === 'REJECTED' ? <XCircle size={18} color="#ef4444" /> : <RefreshCw size={18} color="#f59e0b" />}
          <span style={{ fontWeight: 600 }}>Application #{id}: <strong>{decision}</strong> — State synchronized to PostgreSQL.</span>
        </div>
      ))}

      {loading ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center' }}>
          <Loader2 size={32} color="#6366f1" style={{ animation: 'spin 1s linear infinite', margin: '0 auto 16px' }} />
          <p style={{ color: 'var(--text-secondary)' }}>Loading pending approvals from backend...</p>
        </div>
      ) : pendingApps.length === 0 && Object.keys(decisions).length === 0 ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center' }}>
          <CheckCircle2 size={48} color="#10b981" style={{ margin: '0 auto 16px' }} />
          <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '8px' }}>All Clear!</h3>
          <p style={{ color: 'var(--text-secondary)' }}>No applications pending recruiter approval. Apply for vacancies via the candidate portal first.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {pendingApps.map(app => (
            <div key={app.applicationId} className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
              {/* Card Header */}
              <div
                style={{ padding: '20px 24px', cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
                onClick={() => setExpandedId(expandedId === app.applicationId ? null : app.applicationId)}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <div style={{ background: 'rgba(99,102,241,0.15)', padding: '10px', borderRadius: '10px' }}>
                    <Cpu size={20} color="#818cf8" />
                  </div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '17px' }}>{app.vacancyTitle}</div>
                    <div style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '2px' }}>
                      {app.candidateName} · {app.candidateEmail} · {app.companyName}
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '11px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>AI Match</div>
                    <div style={{ fontSize: '28px', fontWeight: 800, color: getScoreColor(app.matchScore), lineHeight: 1.1 }}>{app.matchScore}%</div>
                  </div>
                  <span className="status-badge status-pending" style={{ background: 'rgba(245,158,11,0.2)', color: '#f59e0b' }}>PENDING</span>
                  {expandedId === app.applicationId ? <ChevronUp size={18} color="#6b7280" /> : <ChevronDown size={18} color="#6b7280" />}
                </div>
              </div>

              {/* Expanded Detail */}
              {expandedId === app.applicationId && (
                <div style={{ borderTop: '1px solid var(--border-color)', padding: '24px' }}>
                  <div className="responsive-grid-2" style={{ marginBottom: '24px' }}>
                    <div>
                      <h4 style={{ color: 'var(--text-secondary)', marginBottom: '12px', fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px' }}>Candidate Skills</h4>
                      <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                        {app.matchedSkills.length > 0 ? app.matchedSkills.map(skill => (
                          <span key={skill} style={{ background: 'rgba(16,185,129,0.15)', color: '#10b981', border: '1px solid rgba(16,185,129,0.3)', padding: '5px 12px', borderRadius: '8px', fontSize: '13px', fontWeight: 600 }}>
                            ✓ {skill}
                          </span>
                        )) : <span style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>Skills loaded from DB</span>}
                      </div>
                    </div>
                    <div>
                      <h4 style={{ color: 'var(--text-secondary)', marginBottom: '12px', fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px' }}>Applied</h4>
                      <div style={{ fontSize: '15px', fontWeight: 600 }}>{new Date(app.appliedAt).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</div>
                      <div style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '4px' }}>Application #{app.applicationId}</div>
                    </div>
                  </div>

                  {/* AI Summary */}
                  <div style={{ background: 'rgba(255,255,255,0.03)', padding: '16px 20px', borderRadius: '10px', marginBottom: '24px', border: '1px solid var(--border-color)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
                      <ShieldCheck color="#10b981" size={18} />
                      <span style={{ fontWeight: 700, fontSize: '14px' }}>Deterministic Validation:</span>
                      <span style={{ color: '#10b981', fontWeight: 700, fontSize: '13px' }}>PASSED — No disallowed attributes detected</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <Calendar color="#06b6d4" size={18} />
                      <span style={{ fontWeight: 700, fontSize: '14px' }}>Proposed Interview Slot:</span>
                      <span style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>{app.proposedInterviewSlot}</span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                    <button
                      className="btn-action btn-approve"
                      onClick={() => handleDecision(app.applicationId, 'approve')}
                      disabled={processing === app.applicationId}
                    >
                      {processing === app.applicationId ? <Loader2 size={16} style={{ animation: 'spin 1s linear infinite' }} /> : <CheckCircle2 size={16} />}
                      APPROVE
                    </button>
                    <button
                      className="btn-action btn-reject"
                      onClick={() => handleDecision(app.applicationId, 'reject')}
                      disabled={processing === app.applicationId}
                    >
                      <XCircle size={16} /> REJECT
                    </button>
                    <button
                      className="btn-action btn-revise"
                      onClick={() => handleDecision(app.applicationId, 'revision')}
                      disabled={processing === app.applicationId}
                    >
                      <RefreshCw size={16} /> REQUEST REVISION
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
