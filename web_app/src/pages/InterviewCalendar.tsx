import { useAuth } from '../context/AuthContext';
import React, { useState, useEffect } from 'react';
import {
  Calendar, Clock, User, Video, CheckCircle, XCircle,
  RefreshCw, Star, MessageSquare, AlertCircle, Plus
} from 'lucide-react';
import { api } from '../services/api';
import type { InterviewItem, InterviewSlot } from '../services/api';

type StatusFilter = 'ALL' | 'SCHEDULED' | 'CONFIRMED' | 'RESCHEDULED' | 'COMPLETED' | 'CANCELLED';

const STATUS_COLORS: Record<string, string> = {
  SCHEDULED:   'status-pending',
  CONFIRMED:   'status-approved',
  RESCHEDULED: 'status-revision',
  COMPLETED:   'status-approved',
  CANCELLED:   'status-rejected',
};

const OUTCOME_COLORS: Record<string, { bg: string; color: string }> = {
  RECOMMEND_HIRE: { bg: 'rgba(16,185,129,0.15)', color: '#10b981' },
  REJECT:         { bg: 'rgba(239,68,68,0.15)',  color: '#ef4444' },
  SECOND_ROUND:   { bg: 'rgba(245,158,11,0.15)', color: '#f59e0b' },
};

export const InterviewCalendar: React.FC = () => {
  const { user } = useAuth();
  const isCandidate = user?.role === 'Candidate';
  const canManage = user?.role === 'Recruiter' || user?.role === 'Administrator';
  const token = user?.token ?? "";
  const [activeTab, setActiveTab]         = useState<'schedule' | 'slots'>('schedule');
  const [interviews, setInterviews]       = useState<InterviewItem[]>([]);
  const [slots, setSlots]                 = useState<InterviewSlot[]>([]);
  const [statusFilter, setStatusFilter]   = useState<StatusFilter>('ALL');
  const [loading, setLoading]             = useState(true);
  const [error, setError] = useState('');
  const [slotsLoading, setSlotsLoading]   = useState(false);

  // Feedback modal state
  const [feedbackModal, setFeedbackModal] = useState<{ open: boolean; interviewId: number | null }>({ open: false, interviewId: null });
  const [feedbackComments, setFeedbackComments]  = useState('');
  const [feedbackOutcome, setFeedbackOutcome]    = useState<'RECOMMEND_HIRE' | 'REJECT' | 'SECOND_ROUND'>('RECOMMEND_HIRE');
  const [scores, setScores] = useState([
    { metricName: 'Technical Competency', score: 4 },
    { metricName: 'Problem Solving & Analytical Ability', score: 4 },
    { metricName: 'Communication & Culture Fit', score: 4 },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const loadInterviews = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await api.getInterviews(token);
      setInterviews(data);
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Unable to load interviews.';
      setError(message);
      showToast(message, 'error');
    } finally { setLoading(false); }
  };

  const loadSlots = async () => {
    setSlotsLoading(true);
    const data = await api.getAvailableInterviewSlots(token);
    setSlots(data);
    setSlotsLoading(false);
  };

  useEffect(() => {
    loadInterviews();
  }, [token]);

  useEffect(() => {
    if (activeTab === 'slots') loadSlots();
  }, [activeTab]);

  const filteredInterviews = statusFilter === 'ALL'
    ? interviews
    : interviews.filter(i => i.status === statusFilter);

  const handleCancel = async (id: number) => {
    const reason = window.prompt('Please enter the reason for cancellation:', 'Schedule conflict / Candidate requested');
    if (!reason) return;

    setActionLoading(id);
    const ok = await api.cancelInterview(id, reason, token);
    if (ok) {
      showToast('Interview cancelled successfully and slot released.');
      await loadInterviews();
    } else {
      showToast('Failed to cancel interview.', 'error');
    }
    setActionLoading(null);
  };

  const handleSuggestSlot = async (id: number) => {
    setActionLoading(id);
    const result = await api.suggestConflictFreeSlot(id, token);
    if (result) {
      const time = new Date(result.suggestedStartTime).toLocaleString('en-GB', { dateStyle: 'medium', timeStyle: 'short' });
      showToast(`🤖 AI Conflict-Free Slot: ${time} (${result.durationMinutes} mins)`);
    } else {
      showToast('Failed to fetch slot suggestion.', 'error');
    }
    setActionLoading(null);
  };

  const openFeedbackModal = (id: number) => {
    setFeedbackComments('');
    setFeedbackOutcome('RECOMMEND_HIRE');
    setScores([
      { metricName: 'Technical Competency', score: 4 },
      { metricName: 'Problem Solving & Analytical Ability', score: 4 },
      { metricName: 'Communication & Culture Fit', score: 4 },
    ]);
    setFeedbackModal({ open: true, interviewId: id });
  };

  const handleSubmitFeedback = async () => {
    if (!feedbackModal.interviewId) return;
    if (!feedbackComments.trim()) {
      showToast('Please enter evaluation comments before submitting.', 'error');
      return;
    }

    setSubmitting(true);
    try {
      for (const s of scores) {
        await api.addInterviewScore(feedbackModal.interviewId, s.metricName, s.score, token);
      }
      await api.addInterviewFeedback(feedbackModal.interviewId, feedbackComments, feedbackOutcome, token);
      showToast('✅ Evaluation & scores saved! Interview marked as COMPLETED.');
      setFeedbackModal({ open: false, interviewId: null });
      await loadInterviews();
    } catch {
      showToast('Failed to submit evaluation. Please try again.', 'error');
    }
    setSubmitting(false);
  };

  const avgScore = (interview: InterviewItem) => {
    if (!interview.scores || interview.scores.length === 0) return null;
    const avg = interview.scores.reduce((a, b) => a + b.score, 0) / interview.scores.length;
    return avg.toFixed(1);
  };

  return (
    <div>
      {/* Toast Notification */}
      {toast && (
        <div style={{
          position: 'fixed', top: '24px', right: '24px', zIndex: 9999,
          background: toast.type === 'success' ? 'rgba(16,185,129,0.95)' : 'rgba(239,68,68,0.95)',
          color: '#fff', padding: '14px 22px', borderRadius: '12px',
          fontWeight: 600, fontSize: '14px', maxWidth: '420px',
          boxShadow: '0 12px 36px rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', gap: '10px'
        }}>
          {toast.type === 'success' ? <CheckCircle size={20} /> : <AlertCircle size={20} />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Human-in-the-Loop Feedback Modal */}
      {feedbackModal.open && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', zIndex: 9000,
          display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '24px'
        }}>
          <div className="glass-panel" style={{ padding: '32px', width: '100%', maxWidth: '580px', maxHeight: '90vh', overflowY: 'auto' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px' }}>
              <MessageSquare size={22} color="#6366f1" />
              Interviewer Evaluation (Human-in-the-Loop)
            </h2>

            {/* Rubric Scores */}
            <div style={{ marginBottom: '24px' }}>
              <div style={{ fontSize: '13px', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '14px', letterSpacing: '0.5px' }}>
                RUBRIC EVALUATION (1 TO 5 SCALE)
              </div>
              {scores.map((s, idx) => (
                <div key={s.metricName} style={{ marginBottom: '16px', background: 'rgba(255,255,255,0.02)', padding: '12px 16px', borderRadius: '10px', border: '1px solid var(--border-color)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span style={{ fontSize: '13px', fontWeight: 600 }}>{s.metricName}</span>
                    <span style={{ fontSize: '13px', color: '#818cf8', fontWeight: 700 }}>{s.score} / 5</span>
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    {[1, 2, 3, 4, 5].map(v => (
                      <button
                        key={v}
                        type="button"
                        onClick={() => {
                          const updated = [...scores];
                          updated[idx] = { ...updated[idx], score: v };
                          setScores(updated);
                        }}
                        style={{
                          flex: 1, height: '36px', borderRadius: '8px',
                          border: s.score === v ? '2px solid #6366f1' : '1px solid var(--border-color)',
                          background: s.score === v ? 'rgba(99,102,241,0.25)' : 'rgba(255,255,255,0.03)',
                          color: s.score === v ? '#a5b4fc' : 'var(--text-secondary)',
                          fontWeight: 700, cursor: 'pointer', fontSize: '14px', transition: 'all 0.2s'
                        }}
                      >
                        {v}
                      </button>
                    ))}
                  </div>
                </div>
              ))}
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginTop: '8px', display: 'flex', justifyContent: 'space-between' }}>
                <span>Calculated Rubric Average:</span>
                <strong style={{ color: '#818cf8' }}>
                  {(scores.reduce((a, b) => a + b.score, 0) / scores.length).toFixed(2)} / 5.0
                </strong>
              </div>
            </div>

            {/* Outcome Recommendation */}
            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '10px', letterSpacing: '0.5px' }}>
                FINAL OUTCOME RECOMMENDATION
              </label>
              <div style={{ display: 'flex', gap: '10px' }}>
                {(['RECOMMEND_HIRE', 'SECOND_ROUND', 'REJECT'] as const).map(o => (
                  <button
                    key={o}
                    type="button"
                    onClick={() => setFeedbackOutcome(o)}
                    style={{
                      flex: 1, padding: '12px 8px', borderRadius: '10px', fontSize: '12px', fontWeight: 700,
                      border: feedbackOutcome === o ? `2px solid ${OUTCOME_COLORS[o].color}` : '1px solid var(--border-color)',
                      background: feedbackOutcome === o ? OUTCOME_COLORS[o].bg : 'rgba(255,255,255,0.03)',
                      color: feedbackOutcome === o ? OUTCOME_COLORS[o].color : 'var(--text-secondary)',
                      cursor: 'pointer', transition: 'all 0.2s'
                    }}
                  >
                    {o.replace(/_/g, ' ')}
                  </button>
                ))}
              </div>
            </div>

            {/* Comments */}
            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '8px', letterSpacing: '0.5px' }}>
                DETAILED EVALUATION COMMENTS
              </label>
              <textarea
                value={feedbackComments}
                onChange={e => setFeedbackComments(e.target.value)}
                placeholder="Detail candidate technical strengths, problem solving ability, and recommended next steps..."
                rows={4}
                style={{
                  width: '100%', padding: '12px 14px', borderRadius: '10px',
                  background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)',
                  color: '#fff', fontSize: '14px', resize: 'vertical', boxSizing: 'border-box'
                }}
              />
            </div>

            {/* Actions */}
            <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
              <button
                type="button"
                onClick={() => setFeedbackModal({ open: false, interviewId: null })}
                className="btn-action btn-reject"
                style={{ padding: '10px 20px' }}
                disabled={submitting}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleSubmitFeedback}
                className="btn-action btn-approve"
                style={{ padding: '10px 24px' }}
                disabled={submitting}
              >
                {submitting ? 'Submitting...' : '✓ Complete Evaluation'}
              </button>
            </div>
          </div>
        </div>
      )}

      {error && <p role="alert">{error}</p>}

      {/* Header Bar */}
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>{isCandidate ? 'Interview Invitations' : 'Interview Schedule & Calendar'}</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Conflict-free scheduling, panel assignments, scoring rubrics & feedback — Component C.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <span style={{
            background: 'rgba(6,182,212,0.15)', color: '#06b6d4',
            padding: '8px 16px', borderRadius: '20px', fontSize: '13px', fontWeight: 600,
            border: '1px solid rgba(6,182,212,0.3)'
          }}>
            {interviews.filter(i => i.status === 'CONFIRMED' || i.status === 'SCHEDULED').length} Active Interviews
          </span>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '6px', marginBottom: '24px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px', padding: '4px', width: 'fit-content', border: '1px solid var(--border-color)' }}>
        <button
          type="button"
          onClick={() => setActiveTab('schedule')}
          style={{
            padding: '10px 24px', borderRadius: '10px', fontWeight: 600, fontSize: '14px',
            background: activeTab === 'schedule' ? 'rgba(99,102,241,0.25)' : 'transparent',
            color: activeTab === 'schedule' ? '#818cf8' : 'var(--text-secondary)',
            border: activeTab === 'schedule' ? '1px solid rgba(99,102,241,0.4)' : '1px solid transparent',
            cursor: 'pointer', transition: 'all 0.2s'
          }}
        >
          📅 Interviews Schedule
        </button>
        <button
          type="button"
          disabled={isCandidate}
          onClick={() => setActiveTab('slots')}
          style={{
            padding: '10px 24px', borderRadius: '10px', fontWeight: 600, fontSize: '14px',
            background: activeTab === 'slots' ? 'rgba(99,102,241,0.25)' : 'transparent',
            color: activeTab === 'slots' ? '#818cf8' : 'var(--text-secondary)',
            border: activeTab === 'slots' ? '1px solid rgba(99,102,241,0.4)' : '1px solid transparent',
            cursor: 'pointer', transition: 'all 0.2s'
          }}
        >
          🕐 Available Slots & Availability
        </button>
      </div>

      {/* ===== TAB 1: INTERVIEWS SCHEDULE ===== */}
      {activeTab === 'schedule' && (
        <div>
          {/* Status Filter Pills */}
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '20px' }}>
            {(['ALL', 'SCHEDULED', 'CONFIRMED', 'RESCHEDULED', 'COMPLETED', 'CANCELLED'] as StatusFilter[]).map(f => (
              <button
                key={f}
                type="button"
                onClick={() => setStatusFilter(f)}
                style={{
                  padding: '6px 14px', borderRadius: '20px', fontSize: '12px', fontWeight: 600,
                  background: statusFilter === f ? 'rgba(99,102,241,0.25)' : 'rgba(255,255,255,0.04)',
                  color: statusFilter === f ? '#818cf8' : 'var(--text-secondary)',
                  border: statusFilter === f ? '1px solid rgba(99,102,241,0.4)' : '1px solid var(--border-color)',
                  cursor: 'pointer', transition: 'all 0.2s'
                }}
              >
                {f} {f === 'ALL' ? `(${interviews.length})` : `(${interviews.filter(i => i.status === f).length})`}
              </button>
            ))}
          </div>

          {loading ? (
            <div className="glass-panel" style={{ padding: '48px', textAlign: 'center' }}>
              <div style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>⏳ Loading interviews from backend...</div>
            </div>
          ) : !error && filteredInterviews.length === 0 ? (
            <div className="glass-panel" style={{ padding: '48px', textAlign: 'center' }}>
              <Calendar size={40} color="var(--text-secondary)" style={{ marginBottom: '12px' }} />
              <div style={{ fontSize: '16px', fontWeight: 600, marginBottom: '6px' }}>No Interviews Found</div>
              <div style={{ fontSize: '14px', color: 'var(--text-secondary)' }}>
                {statusFilter !== 'ALL' ? `No interviews matching status "${statusFilter}".` : 'No interviews scheduled yet.'}
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {filteredInterviews.map(iv => {
                const candidateName  = iv.application?.candidate?.user?.fullName ?? 'Candidate name unavailable';
                const vacancyTitle   = iv.application?.vacancy?.title ?? 'Vacancy title unavailable';
                const interviewerName = iv.interviewer?.user?.fullName ?? 'Not assigned';
                const scheduledDate  = new Date(iv.scheduledTime).toLocaleString('en-GB', { dateStyle: 'medium', timeStyle: 'short' });
                const feedback       = iv.feedbacks?.[0];
                const avgS           = avgScore(iv);

                return (
                  <div key={iv.id} className="glass-panel" style={{
                    padding: '22px 26px',
                    borderLeft: `4px solid ${
                      iv.status === 'CONFIRMED' ? '#10b981' :
                      iv.status === 'COMPLETED' ? '#6366f1' :
                      iv.status === 'CANCELLED' ? '#ef4444' : '#f59e0b'
                    }`
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', flexWrap: 'wrap' }}>
                      {/* Interview Information */}
                      <div style={{ flex: 1, minWidth: '280px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px', flexWrap: 'wrap' }}>
                          <span className={`status-badge ${STATUS_COLORS[iv.status] ?? 'status-pending'}`}>
                            {iv.status}
                          </span>
                          {avgS && (
                            <span style={{ background: 'rgba(99,102,241,0.15)', color: '#818cf8', padding: '3px 10px', borderRadius: '12px', fontSize: '12px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px' }}>
                              <Star size={12} /> {avgS} / 5
                            </span>
                          )}
                          {feedback && (
                            <span style={{
                              ...OUTCOME_COLORS[feedback.outcomeRecommendation],
                              padding: '3px 10px', borderRadius: '12px', fontSize: '11px', fontWeight: 700
                            }}>
                              {feedback.outcomeRecommendation.replace(/_/g, ' ')}
                            </span>
                          )}
                        </div>

                        <div style={{ fontSize: '18px', fontWeight: 700, marginBottom: '8px' }}>
                          {vacancyTitle}
                        </div>

                        <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', color: 'var(--text-secondary)', fontSize: '13px' }}>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <User size={14} /> {candidateName}
                          </span>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <Clock size={14} /> {scheduledDate} ({iv.durationMinutes} mins)
                          </span>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                            <Video size={14} /> {iv.meetingLinkOrLocation?.startsWith('http')
                              ? <a href={iv.meetingLinkOrLocation} target="_blank" rel="noreferrer" style={{ color: '#06b6d4', textDecoration: 'underline' }}>Join Meeting</a>
                              : (iv.meetingLinkOrLocation || 'Online Meeting')
                            }
                          </span>
                        </div>

                        {interviewerName && (
                          <div style={{ marginTop: '10px', fontSize: '12px', color: '#818cf8', fontWeight: 600 }}>
                            👨‍🏫 Panel Interviewer: {interviewerName} · {iv.interviewer?.department ?? 'Engineering'}
                          </div>
                        )}

                        {feedback?.comments && (
                          <div style={{
                            marginTop: '12px', padding: '10px 14px', borderRadius: '8px',
                            background: 'rgba(255,255,255,0.03)', fontSize: '13px', color: 'var(--text-secondary)',
                            borderLeft: '3px solid rgba(99,102,241,0.5)', fontStyle: 'italic'
                          }}>
                            "{feedback.comments}"
                          </div>
                        )}
                      </div>

                      {/* Non-CRUD Action Buttons */}
                      {!isCandidate && !['COMPLETED', 'CANCELLED'].includes(iv.status) && (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', minWidth: '170px' }}>
                          <button
                            type="button"
                            className="btn-action btn-approve"
                            onClick={() => openFeedbackModal(iv.id)}
                            style={{ padding: '8px 14px', fontSize: '12px', display: 'flex', alignItems: 'center', gap: '6px', justifyContent: 'center' }}
                          >
                            <Star size={14} /> Submit Evaluation
                          </button>
                          <button
                            type="button"
                            className="btn-action"
                            onClick={() => handleSuggestSlot(iv.id)}
                            disabled={actionLoading === iv.id}
                            style={{
                              padding: '8px 14px', fontSize: '12px',
                              background: 'rgba(6,182,212,0.1)', color: '#06b6d4',
                              border: '1px solid rgba(6,182,212,0.3)',
                              display: 'flex', alignItems: 'center', gap: '6px', justifyContent: 'center'
                            }}
                          >
                            <RefreshCw size={14} /> Suggest AI Slot
                          </button>
                          <button
                            type="button"
                            className="btn-action btn-reject"
                            onClick={() => handleCancel(iv.id)}
                            disabled={!canManage || actionLoading === iv.id}
                            style={{ padding: '8px 14px', fontSize: '12px', display: 'flex', alignItems: 'center', gap: '6px', justifyContent: 'center' }}
                          >
                            <XCircle size={14} /> Cancel
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ===== TAB 2: AVAILABLE SLOTS & AVAILABILITY ===== */}
      {activeTab === 'slots' && (
        <div>
          <div className="glass-panel" style={{ padding: '24px' }}>
            <h2 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Plus size={20} color="#06b6d4" />
              Available Interview Slots
            </h2>

            {slotsLoading ? (
              <div style={{ textAlign: 'center', padding: '32px', color: 'var(--text-secondary)' }}>⏳ Loading slots...</div>
            ) : slots.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '32px', color: 'var(--text-secondary)' }}>
                No available interview slots published yet.
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '16px' }}>
                {slots.map(slot => {
                  const start = new Date(slot.slotStartTime).toLocaleString('en-GB', { dateStyle: 'medium', timeStyle: 'short' });
                  const end   = new Date(slot.slotEndTime).toLocaleTimeString('en-GB', { timeStyle: 'short' });
                  return (
                    <div key={slot.id} style={{
                      background: slot.isBooked ? 'rgba(239,68,68,0.06)' : 'rgba(16,185,129,0.06)',
                      border: `1px solid ${slot.isBooked ? 'rgba(239,68,68,0.25)' : 'rgba(16,185,129,0.25)'}`,
                      borderRadius: '12px', padding: '18px'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                        <span style={{ fontSize: '12px', fontWeight: 700, color: slot.isBooked ? '#ef4444' : '#10b981' }}>
                          {slot.isBooked ? '🔒 BOOKED' : '✅ AVAILABLE'}
                        </span>
                        <span style={{ fontSize: '11px', color: 'var(--text-secondary)' }}>45 mins</span>
                      </div>
                      <div style={{ fontWeight: 700, fontSize: '15px', marginBottom: '4px' }}>{start}</div>
                      <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Until {end}</div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Weekly Availability Schedule */}
          <div className="glass-panel" style={{ padding: '24px', marginTop: '20px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Calendar size={18} color="#6366f1" /> Panel Weekly Availability Schedule
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '12px' }}>
              {[
                { day: 'Monday',    hours: '09:00 – 17:00', dept: 'Software Architecture' },
                { day: 'Wednesday', hours: '10:00 – 16:00', dept: 'Cloud & DevOps' },
                { day: 'Friday',    hours: '13:00 – 17:00', dept: 'AI & Data Engineering' },
              ].map(a => (
                <div key={a.day} style={{
                  background: 'rgba(99,102,241,0.08)', border: '1px solid rgba(99,102,241,0.2)',
                  borderRadius: '10px', padding: '14px'
                }}>
                  <div style={{ fontWeight: 700, fontSize: '14px', marginBottom: '4px' }}>{a.day}</div>
                  <div style={{ fontSize: '13px', color: '#818cf8', fontWeight: 600 }}>{a.hours}</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-secondary)', marginTop: '4px' }}>{a.dept}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
export default InterviewCalendar;
