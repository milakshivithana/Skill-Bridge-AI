import React, { useEffect, useState } from 'react';
import { api, type Application } from '../services/api';
import { Sparkles, XCircle, History } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const MyApplications: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? "";


  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [evaluatingAppId, setEvaluatingAppId] = useState<number | null>(null);
  const [selectedAppForHistory, setSelectedAppForHistory] = useState<Application | null>(null);
  const [withdrawReason, setWithdrawReason] = useState('');
  const [showWithdrawModal, setShowWithdrawModal] = useState<number | null>(null);

  const fetchApplications = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await api.getMyApplications(token);
      setApplications(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unable to load data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchApplications();
  }, [token]);

  const handleRunAiEvaluation = async (appId: number) => {
    setEvaluatingAppId(appId);
    setError('');
    try {
      await api.evaluateApplicationMatch(appId, token);
      await fetchApplications();
    } catch (e) {
      const message = e instanceof Error ? e.message : 'AI Evaluation failed';
      setError(message);
      alert(message);
    } finally {
      setEvaluatingAppId(null);
    }
  };

  const handleWithdraw = async (appId: number) => {
    try {
      await api.withdrawApplication(appId, withdrawReason || 'Withdrawn by candidate.', token);
      setShowWithdrawModal(null);
      setWithdrawReason('');
      await fetchApplications();
    } catch (err: any) {
      alert(err.message || 'Failed to withdraw application');
    }
  };

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>My Application Pipeline & Status</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Track application progress, review status history timeline, and manage submitted applications.
          </p>
        </div>
      </div>

      {error && <p role="alert">{error}</p>}
      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          Loading candidate applications...
        </div>
      ) : !error && applications.length === 0 ? (
        <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          You have not submitted any applications yet. Browse available vacancies to apply.
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {applications.map(app => (
            <div key={app.id} className="glass-panel" style={{ padding: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                <div>
                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>
                    Application #{app.id} - Applied: {new Date(app.appliedAt).toLocaleDateString()}
                  </span>
                  <h3 style={{ fontSize: '20px', fontWeight: 700, marginTop: '4px' }}>{app.vacancyTitle || app.vacancy?.title || 'Vacancy unavailable'}</h3>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>Company: {app.companyName || app.vacancy?.company?.name || 'Company not specified'}</p>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span className={`status-badge status-${app.status.toLowerCase().replace(/_/g, '-')}`} style={{ fontSize: '13px', padding: '6px 14px' }}>
                    {app.status}
                  </span>
                  {app.evaluation && (
                    <div style={{ marginTop: '8px' }}>
                      <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>Match Score</span>
                      <div style={{ fontSize: '24px', fontWeight: 800, color: '#10b981' }}>{app.evaluation.matchScore}%</div>
                    </div>
                  )}
                </div>
              </div>

              {app.status === 'PENDING_RECRUITER_APPROVAL' && (
                <p style={{ fontSize: '13px', color: '#f59e0b', marginBottom: '12px' }}>
                  Awaiting recruiter review and approval.
                </p>
              )}
              {app.status === 'APPROVED' && (
                <p style={{ fontSize: '13px', color: '#10b981', marginBottom: '12px' }}>
                  Approved! Check Interview Invitations for scheduled interview details.
                </p>
              )}

              <div aria-label="AI Evaluation">
                <strong>AI Evaluation (advisory)</strong>
                {!app.evaluation ? <p>AI evaluation has not been run yet</p> : <>
                  {!app.evaluation.evidence && <p>Detailed evidence is unavailable for this saved evaluation.</p>}
                  {Object.entries({
                    'Matched required skills': app.evaluation.evidence?.matched_required_skills,
                    'Matched skills': app.evaluation.evidence?.matched_required_skills === undefined ? app.evaluation.evidence?.matched_skills : undefined,
                    'Missing required skills': app.evaluation.evidence?.missing_required_skills,
                    'Matched preferred skills': app.evaluation.evidence?.matched_preferred_skills,
                    'Missing preferred skills': app.evaluation.evidence?.missing_preferred_skills,
                  }).map(([label, skills]) => skills !== undefined && <p key={label}>{label}: {skills.length ? skills.join(', ') : 'None'}</p>)}
                  {app.evaluation.evidence?.reasoning && <p>{app.evaluation.evidence.reasoning}</p>}
                  {(['education_evidence', 'experience_evidence'] as const).map(key => app.evaluation?.evidence?.[key]?.map((record, index) =>
                    <p key={`${key}-${index}`}>{key === 'education_evidence' ? 'Education' : 'Experience'}: {Object.values(record).filter(v => v != null && v !== '').map(String).join(' - ')}</p>
                  ))}
                  {app.evaluation.evidence?.requirements_review?.map((r, index) => (
                    <p key={index}>
                      {r.text.replace(/\.$/, '')}:{' '}
                      {r.result === 'REQUIRES_HUMAN_REVIEW'
                        ? 'REQUIRES RECRUITER REVIEW'
                        : r.result}
                    </p>
                  ))}
                  <p>The recruiter makes the final decision.</p>
                </>}
              </div>

              {/* Action Toolbar */}
              <div style={{ display: 'flex', gap: '10px', paddingTop: '16px', borderTop: '1px solid var(--border-color)', marginTop: '16px', flexWrap: 'wrap', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <button className="btn-secondary" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => setSelectedAppForHistory(app)}>
                    <History size={14} /> Status History ({app.statusHistories?.length || 0})
                  </button>

                  {(app.status === 'SUBMITTED' || app.status === 'REVISION_REQUESTED') && (
                    <button className="btn-action btn-approve" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => handleRunAiEvaluation(app.id)} disabled={evaluatingAppId !== null}>
                      <Sparkles size={14} /> {evaluatingAppId === app.id ? 'Running AI Match...' : 'Run Agentic AI Evaluation'}
                    </button>
                  )}
                </div>

                {app.status !== 'WITHDRAWN' && app.status !== 'REJECTED' && app.status !== 'APPROVED' && (
                  <button className="btn-secondary" style={{ color: '#ef4444', borderColor: 'rgba(239,68,68,0.3)', fontSize: '12px', padding: '6px 12px' }} onClick={() => setShowWithdrawModal(app.id)}>
                    <XCircle size={14} /> Withdraw Application
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Status History Modal */}
      {selectedAppForHistory && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '90%', maxWidth: '600px', padding: '24px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '18px', fontWeight: 700 }}>Application Status History</h3>
                <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>{selectedAppForHistory.vacancyTitle || selectedAppForHistory.vacancy?.title}</p>
              </div>
              <button className="btn-secondary" onClick={() => setSelectedAppForHistory(null)}>Close</button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {selectedAppForHistory.statusHistories && selectedAppForHistory.statusHistories.length > 0 ? (
                selectedAppForHistory.statusHistories.map(sh => (
                  <div key={sh.id} style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-color)', padding: '14px', borderRadius: '8px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                      <span className={`status-badge status-${sh.status.toLowerCase().replace(/_/g, '-')}`}>{sh.status}</span>
                      <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>{new Date(sh.changedAt).toLocaleString()}</span>
                    </div>
                    <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '4px' }}>{sh.notes}</p>
                  </div>
                ))
              ) : (
                <div style={{ padding: '20px', textAlign: 'center', color: 'var(--text-secondary)' }}>No status history recorded.</div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Withdraw Modal */}
      {showWithdrawModal && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '90%', maxWidth: '500px', padding: '24px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '12px', color: '#ef4444' }}>Confirm Application Withdrawal</h3>
            <p style={{ fontSize: '14px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
              Are you sure you want to withdraw this application? This action will update your status and notify the recruiter.
            </p>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Reason for Withdrawal (Optional)</label>
              <input
                type="text"
                value={withdrawReason}
                onChange={e => setWithdrawReason(e.target.value)}
                placeholder="e.g. Accepted another offer"
                style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button className="btn-secondary" onClick={() => setShowWithdrawModal(null)}>Cancel</button>
              <button className="btn-action btn-reject" onClick={() => handleWithdraw(showWithdrawModal)}>Confirm Withdrawal</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
