import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type AuditLogEntry } from '../services/api';
import { Shield, Loader2, Filter, Clock } from 'lucide-react';

const ACTION_COLORS: Record<string, { bg: string; color: string; label: string }> = {
  APPROVE_APPLICATION: { bg: 'rgba(16,185,129,0.15)', color: '#10b981', label: 'Approved' },
  REJECT_APPLICATION:  { bg: 'rgba(239,68,68,0.15)',  color: '#ef4444', label: 'Rejected' },
  REQUEST_REVISION:    { bg: 'rgba(245,158,11,0.15)', color: '#f59e0b', label: 'Revision' },
  DEFAULT:             { bg: 'rgba(99,102,241,0.15)', color: '#818cf8', label: 'Action' },
};

const getActionStyle = (action: string) => ACTION_COLORS[action] ?? ACTION_COLORS.DEFAULT;

export const AuditLog: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? '';
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [filter, setFilter] = useState('ALL');

  useEffect(() => {
    api.getAuditLogs(token).then(res => {
      setLogs(res.logs);
      setTotal(res.total);
      setLoading(false);
    });
  }, [token]);

  const filtered = filter === 'ALL' ? logs : logs.filter(l => l.action === filter);

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>System Audit Log</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Complete tamper-evident record of all recruiter decisions and system actions.
          </p>
        </div>
        <div style={{ background: 'rgba(99,102,241,0.15)', border: '1px solid rgba(99,102,241,0.3)', padding: '8px 16px', borderRadius: '10px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Shield size={16} color="#818cf8" />
          <span style={{ color: '#818cf8', fontWeight: 700 }}>{total} Total Actions</span>
        </div>
      </div>

      {/* Filter Tabs */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '20px' }}>
        {['ALL', 'APPROVE_APPLICATION', 'REJECT_APPLICATION', 'REQUEST_REVISION'].map(f => (
          <button key={f} onClick={() => setFilter(f)} style={{
            padding: '7px 16px', borderRadius: '8px', border: '1px solid',
            fontSize: '13px', fontWeight: 600, cursor: 'pointer',
            background: filter === f ? 'rgba(99,102,241,0.2)' : 'transparent',
            borderColor: filter === f ? 'rgba(99,102,241,0.5)' : 'var(--border-color)',
            color: filter === f ? '#818cf8' : 'var(--text-secondary)',
            display: 'flex', alignItems: 'center', gap: '6px'
          }}>
            {f === 'ALL' ? <Filter size={12} /> : null}
            {f === 'ALL' ? 'All Actions' : f === 'APPROVE_APPLICATION' ? '✅ Approvals' : f === 'REJECT_APPLICATION' ? '❌ Rejections' : '🔄 Revisions'}
          </button>
        ))}
      </div>

      <div className="glass-panel" style={{ padding: '0', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '60px', textAlign: 'center' }}>
            <Loader2 size={32} color="#6366f1" style={{ margin: '0 auto 16px', animation: 'spin 1s linear infinite' }} />
            <p style={{ color: 'var(--text-secondary)' }}>Loading audit log from backend...</p>
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: '60px', textAlign: 'center' }}>
            <Shield size={48} color="#374151" style={{ margin: '0 auto 16px' }} />
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '8px' }}>No Audit Entries Yet</h3>
            <p style={{ color: 'var(--text-secondary)' }}>Audit entries are created automatically when recruiters approve, reject, or request revisions via the HITL queue.</p>
          </div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-color)' }}>
                {['ID', 'Action', 'Entity', 'Recruiter ID', 'Summary', 'Timestamp'].map(h => (
                  <th key={h} style={{ padding: '14px 20px', textAlign: 'left', fontSize: '12px', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '1px' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((log, idx) => {
                const style = getActionStyle(log.action);
                return (
                  <tr key={log.id} style={{ borderBottom: '1px solid var(--border-color)', background: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.015)', transition: 'background 0.15s' }}>
                    <td style={{ padding: '14px 20px', color: 'var(--text-secondary)', fontSize: '13px' }}>#{log.id}</td>
                    <td style={{ padding: '14px 20px' }}>
                      <span style={{ background: style.bg, color: style.color, padding: '4px 10px', borderRadius: '6px', fontSize: '12px', fontWeight: 700 }}>
                        {style.label}
                      </span>
                    </td>
                    <td style={{ padding: '14px 20px', fontSize: '13px' }}>
                      <span style={{ color: 'var(--text-secondary)' }}>{log.entityType}</span> <strong>#{log.entityId}</strong>
                    </td>
                    <td style={{ padding: '14px 20px', fontSize: '13px', color: 'var(--text-secondary)' }}>User #{log.userId}</td>
                    <td style={{ padding: '14px 20px', fontSize: '13px', color: 'var(--text-secondary)', maxWidth: '300px' }}>{log.summary}</td>
                    <td style={{ padding: '14px 20px', fontSize: '12px', color: 'var(--text-secondary)', whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Clock size={12} />
                      {new Date(log.timestamp).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
