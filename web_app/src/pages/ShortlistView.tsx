import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type ShortlistResponse } from '../services/api';
import { ListOrdered, Star, Loader2, Trophy, ChevronRight } from 'lucide-react';

export const ShortlistView: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? '';
  const [shortlists, setShortlists] = useState<ShortlistResponse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getShortlists(token, user?.role === 'Candidate').then(data => { setShortlists(data); setLoading(false); });
  }, [token, user?.role]);

  const isCandidate = user?.role === 'Candidate';
  const displayedShortlists = isCandidate && user?.email
    ? shortlists
        .map(s => ({
          ...s,
          recommendations: s.recommendations.filter(r => r.candidateEmail.toLowerCase() === user.email.toLowerCase())
        }))
        .filter(s => s.recommendations.length > 0)
    : shortlists;

  const getScoreColor = (score: number) => {
    if (score >= 80) return '#10b981';
    if (score >= 60) return '#f59e0b';
    return '#ef4444';
  };

  const getRankStyle = (rank: number) => {
    if (rank === 0) return { icon: '🥇', color: '#f59e0b' };
    if (rank === 1) return { icon: '🥈', color: '#94a3b8' };
    if (rank === 2) return { icon: '🥉', color: '#b45309' };
    return { icon: `#${rank + 1}`, color: 'var(--text-secondary)' };
  };

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>
            {isCandidate ? 'My AI Shortlists & Match Results' : 'AI Shortlist & Recommendations'}
          </h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            {isCandidate
              ? 'Vacancies where your profile was shortlisted with match scores and AI justifications.'
              : 'AI-ranked candidate shortlists with match scores and justifications per vacancy.'}
          </p>
        </div>
      </div>

      {loading ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center' }}>
          <Loader2 size={32} color="#6366f1" style={{ margin: '0 auto 16px', animation: 'spin 1s linear infinite' }} />
          <p style={{ color: 'var(--text-secondary)' }}>Loading shortlists from backend...</p>
        </div>
      ) : displayedShortlists.length === 0 ? (
        <div className="glass-panel" style={{ padding: '60px', textAlign: 'center' }}>
          <Trophy size={48} color="#6366f1" style={{ margin: '0 auto 16px' }} />
          <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '8px' }}>
            {isCandidate ? 'No Shortlists For Your Account' : 'No Shortlists Yet'}
          </h3>
          <p style={{ color: 'var(--text-secondary)' }}>
            {isCandidate
              ? 'When your application is reviewed and shortlisted by the AI pipeline, it will appear here.'
              : 'Shortlists are generated automatically after the AI matching pipeline completes for a vacancy.'}
          </p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {displayedShortlists.map(shortlist => (
            <div key={shortlist.id} className="glass-panel" style={{ padding: '28px' }}>
              {/* Shortlist Header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '4px' }}>
                    <ListOrdered size={20} color="#6366f1" />
                    <h2 style={{ fontSize: '20px', fontWeight: 700 }}>{shortlist.title}</h2>
                  </div>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                    Vacancy: <strong style={{ color: 'var(--text-primary)' }}>{shortlist.vacancyTitle}</strong> ·
                    Created {new Date(shortlist.createdAt).toLocaleDateString('en-GB')}
                  </p>
                </div>
                <div style={{ background: 'rgba(99,102,241,0.15)', border: '1px solid rgba(99,102,241,0.3)', padding: '6px 14px', borderRadius: '8px' }}>
                  <span style={{ color: '#818cf8', fontWeight: 700, fontSize: '13px' }}>
                    {isCandidate ? 'Your Shortlist Match' : `${shortlist.recommendations.length} Candidates`}
                  </span>
                </div>
              </div>

              {/* Recommendations Ranked List */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {shortlist.recommendations.map((rec, idx) => {
                  const rank = getRankStyle(idx);
                  const isMe = user?.email && rec.candidateEmail.toLowerCase() === user.email.toLowerCase();
                  return (
                    <div key={rec.id} style={{
                      display: 'flex', alignItems: 'center', gap: '16px',
                      padding: '16px 20px', background: isMe ? 'rgba(16,185,129,0.08)' : idx === 0 ? 'rgba(99,102,241,0.08)' : 'rgba(255,255,255,0.03)',
                      borderRadius: '10px', border: `1px solid ${isMe ? 'rgba(16,185,129,0.4)' : idx === 0 ? 'rgba(99,102,241,0.3)' : 'var(--border-color)'}`,
                      transition: 'all 0.2s'
                    }}>
                      {/* Rank */}
                      <div style={{ fontSize: '22px', minWidth: '36px', textAlign: 'center', fontWeight: 800, color: rank.color }}>
                        {rank.icon}
                      </div>

                      {/* Candidate Info */}
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <span style={{ fontWeight: 700, fontSize: '16px' }}>{rec.candidateName}</span>
                          {isMe && (
                            <span style={{
                              background: 'rgba(16,185,129,0.2)',
                              border: '1px solid #10b981',
                              color: '#34d399',
                              fontSize: '11px',
                              fontWeight: 700,
                              padding: '2px 8px',
                              borderRadius: '4px'
                            }}>
                              YOU
                            </span>
                          )}
                        </div>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '2px' }}>{rec.candidateEmail}</div>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '6px', fontStyle: 'italic' }}>
                          {rec.aiJustification}
                        </div>
                      </div>

                      {/* Status */}
                      <div style={{ textAlign: 'center', minWidth: '100px' }}>
                        <span className={`status-badge ${rec.applicationStatus === 'APPROVED' ? 'status-approved' : rec.applicationStatus === 'REJECTED' ? 'status-rejected' : 'status-pending'}`}
                          style={{ fontSize: '11px' }}>
                          {rec.applicationStatus}
                        </span>
                      </div>

                      {/* Match Score */}
                      <div style={{ textAlign: 'right', minWidth: '70px' }}>
                        <div style={{ fontSize: '10px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '4px' }}>Score</div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', justifyContent: 'flex-end' }}>
                          <Star size={14} color={getScoreColor(rec.calculatedScore)} fill={getScoreColor(rec.calculatedScore)} />
                          <span style={{ fontSize: '20px', fontWeight: 800, color: getScoreColor(rec.calculatedScore) }}>
                            {rec.calculatedScore}%
                          </span>
                        </div>
                      </div>

                      <ChevronRight size={16} color="#6b7280" />
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
