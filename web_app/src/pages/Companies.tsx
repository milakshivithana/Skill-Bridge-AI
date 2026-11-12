import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type Company } from '../services/api';
import { Building2, MapPin, Globe, Plus, Briefcase } from 'lucide-react';

export const Companies: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? "";
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(true);

  // Create Modal State
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [name, setName] = useState('');
  const [industry, setIndustry] = useState('Software Development');
  const [location, setLocation] = useState('Colombo');
  const [website, setWebsite] = useState('https://');

  const fetchCompanies = async () => {
    setLoading(true);
    try {
      const data = await api.getCompanies(token);
      setCompanies(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCompanies();
  }, [token]);

  const handleCreateCompany = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    try {
      await api.createCompany({ name, industry, location, website }, token);
      setShowCreateModal(false);
      setName('');
      fetchCompanies();
    } catch (err: any) {
      alert(err.message || 'Failed to create company');
    }
  };

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>Company & Employer Management</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Register and manage recruiting companies, partner organizations, and employer profiles.
          </p>
        </div>

        <button className="btn-action btn-approve" onClick={() => setShowCreateModal(true)}>
          <Plus size={18} />
          Register New Company
        </button>
      </div>

      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          Loading companies...
        </div>
      ) : (
        <div className="cards-grid">
          {companies.map(c => (
            <div key={c.id} className="glass-panel" style={{ padding: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
                <div style={{ background: 'rgba(129, 140, 248, 0.15)', padding: '12px', borderRadius: '12px', color: '#818cf8' }}>
                  <Building2 size={24} />
                </div>
                <div>
                  <h3 style={{ fontSize: '18px', fontWeight: 700 }}>{c.name}</h3>
                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{c.industry}</span>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '20px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <MapPin size={14} /> <span>{c.location}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <Globe size={14} /> <a href={c.website} target="_blank" rel="noreferrer" style={{ color: '#818cf8', textDecoration: 'none' }}>{c.website}</a>
                </div>
              </div>

              <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '14px', marginTop: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '12px', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Briefcase size={14} /> Active Vacancies: <strong>{c.activeVacanciesCount ?? 0}</strong>
                </span>
                <span className="status-badge status-approved">VERIFIED</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Company Modal */}
      {showCreateModal && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '90%', maxWidth: '500px', padding: '24px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '16px' }}>Register Partner Company</h2>

            <form onSubmit={handleCreateCompany}>
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Company Name</label>
                <input type="text" required value={name} onChange={e => setName(e.target.value)} placeholder="e.g. CloudNation Tech" style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Industry</label>
                <input type="text" value={industry} onChange={e => setIndustry(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Location</label>
                <input type="text" value={location} onChange={e => setLocation(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ marginBottom: '20px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Website URL</label>
                <input type="text" value={website} onChange={e => setWebsite(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowCreateModal(false)}>Cancel</button>
                <button type="submit" className="btn-action btn-approve">Register Company</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
