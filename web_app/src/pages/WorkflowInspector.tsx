import React, { useState } from 'react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';

export const WorkflowInspector: React.FC = () => {
  const { user } = useAuth();
  const [id, setId] = useState('');
  const [workflow, setWorkflow] = useState<Record<string, unknown> | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const load = async (event: React.FormEvent) => {
    event.preventDefault();
    setWorkflow(null);
    setError('');
    setLoading(true);
    try {
      setWorkflow(await api.getAIWorkflow(Number(id), user?.token ?? ''));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to load workflow.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="header-bar"><h1>Agentic AI Execution Audit</h1></div>
      <form onSubmit={load} style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
        <label>Workflow ID <input type="number" min="1" required value={id} onChange={e => setId(e.target.value)} /></label>
        <button className="btn-action btn-approve" disabled={loading}>{loading ? 'Loading...' : 'Load workflow'}</button>
      </form>
      {error && <p role="alert">{error}</p>}
      {workflow ? <pre className="glass-panel" style={{ padding: '24px', whiteSpace: 'pre-wrap' }}>{JSON.stringify(workflow, null, 2)}</pre>
        : !error && !loading && <p>Select a workflow to view its recorded execution.</p>}
    </div>
  );
};
