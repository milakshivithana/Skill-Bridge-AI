import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import { Cpu, LogIn, User, Briefcase, Shield, UserCheck, AlertCircle } from 'lucide-react';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { loginUser } = useAuth();
  const navigate = useNavigate();

  const handleLogin = async (loginEmail: string, loginPass: string) => {
    setError(null);
    setLoading(true);
    try {
      const user = await api.login({ email: loginEmail, password: loginPass });
      loginUser(user);

      // Navigate based on authentic user role
      if (user.role === 'Candidate') {
        navigate('/candidate-profile');
      } else if (user.role === 'Interviewer') {
        navigate('/interviews');
      } else {
        navigate('/'); // Recruiter / Admin Dashboard
      }
    } catch (err: any) {
      setError(err.message || 'Invalid email or password.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    handleLogin(email, password);
  };

  const quickLoginAs = (role: 'Candidate' | 'Recruiter' | 'Interviewer' | 'Administrator') => {
    let targetEmail = '';
    let targetPass = '';

    if (role === 'Candidate') {
      targetEmail = 'candidate102@student.sliit.lk';
      targetPass = 'Candidate123!';
    } else if (role === 'Recruiter') {
      targetEmail = 'recruiter@techcorp.com';
      targetPass = 'Recruiter123!';
    } else if (role === 'Interviewer') {
      targetEmail = 'interviewer@techcorp.com';
      targetPass = 'Interviewer123!';
    } else {
      targetEmail = 'admin@skillbridge.lk';
      targetPass = 'Admin123!';
    }

    setEmail(targetEmail);
    setPassword(targetPass);
    handleLogin(targetEmail, targetPass);
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
      <div className="glass-panel" style={{ width: '100%', maxWidth: '480px', padding: '40px' }}>
        <div style={{ textAlign: 'center', marginBottom: '32px' }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(99, 102, 241, 0.15)', padding: '16px', borderRadius: '50%', marginBottom: '16px' }}>
            <Cpu size={36} color="#6366f1" />
          </div>
          <h2 style={{ fontSize: '26px', fontWeight: 700 }}>SkillBridge AI Sign In</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginTop: '6px' }}>
            Intelligent Internship & Recruitment Platform
          </p>
        </div>

        {error && (
          <div style={{ background: 'rgba(239, 68, 68, 0.15)', border: '1px solid rgba(239, 68, 68, 0.4)', color: '#ef4444', padding: '12px 16px', borderRadius: '8px', marginBottom: '20px', fontSize: '13px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <AlertCircle size={18} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '13px', fontWeight: 600, marginBottom: '8px' }}>
              Email Address
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="e.g. candidate102@student.sliit.lk"
              required
              style={{ width: '100%', padding: '12px 16px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', outline: 'none' }}
            />
          </div>

          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '13px', fontWeight: 600, marginBottom: '8px' }}>
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              style={{ width: '100%', padding: '12px 16px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', outline: 'none' }}
            />
          </div>

          <button type="submit" className="btn-action btn-approve" style={{ width: '100%', justifyContent: 'center', padding: '12px' }} disabled={loading}>
            <LogIn size={18} />
            {loading ? 'Authenticating...' : 'Sign In'}
          </button>
        </form>

        <div style={{ marginTop: '20px', textAlign: 'center', fontSize: '14px', color: 'var(--text-secondary)' }}>
          Don't have an account?{' '}
          <Link to="/register" style={{ color: '#818cf8', fontWeight: 600, textDecoration: 'none' }}>
            Sign Up here
          </Link>
        </div>

        <div style={{ marginTop: '28px', paddingTop: '20px', borderTop: '1px solid var(--border-color)', textAlign: 'center' }}>
          <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '12px', fontWeight: 600 }}>
            ⚡ Sign In as Database Seeded Account:
          </p>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <button onClick={() => quickLoginAs('Candidate')} type="button" style={{ padding: '8px 12px', borderRadius: '8px', background: 'rgba(6,182,212,0.15)', border: '1px solid rgba(6,182,212,0.3)', color: '#67e8f9', cursor: 'pointer', fontSize: '12px', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
              <User size={14} /> Candidate Log In
            </button>

            <button onClick={() => quickLoginAs('Recruiter')} type="button" style={{ padding: '8px 12px', borderRadius: '8px', background: 'rgba(99,102,241,0.15)', border: '1px solid rgba(99,102,241,0.3)', color: '#818cf8', cursor: 'pointer', fontSize: '12px', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
              <Briefcase size={14} /> Recruiter Log In
            </button>

            <button onClick={() => quickLoginAs('Interviewer')} type="button" style={{ padding: '8px 12px', borderRadius: '8px', background: 'rgba(245,158,11,0.15)', border: '1px solid rgba(245,158,11,0.3)', color: '#fde047', cursor: 'pointer', fontSize: '12px', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
              <UserCheck size={14} /> Interviewer Log In
            </button>

            <button onClick={() => quickLoginAs('Administrator')} type="button" style={{ padding: '8px 12px', borderRadius: '8px', background: 'rgba(16,185,129,0.15)', border: '1px solid rgba(16,185,129,0.3)', color: '#6ee7b7', cursor: 'pointer', fontSize: '12px', fontWeight: 600, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}>
              <Shield size={14} /> Admin Log In
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
