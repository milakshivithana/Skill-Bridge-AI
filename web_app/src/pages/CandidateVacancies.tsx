import React, { useEffect, useState } from 'react';
import { api, type Vacancy, type SavedVacancy } from '../services/api';
import { MapPin, Building2, Send, CheckCircle2, Bookmark, BookmarkCheck, Search, Info } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const CandidateVacancies: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? "";


  const [vacancies, setVacancies] = useState<Vacancy[]>([]);
  const [savedVacancies, setSavedVacancies] = useState<SavedVacancy[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [applying, setApplying] = useState<number | null>(null);

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [locationFilter, setLocationFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');

  // Selected Vacancy Details Modal
  const [selectedVacancy, setSelectedVacancy] = useState<Vacancy | null>(null);

  const fetchVacancies = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.getVacanciesAdvanced({
        searchQuery: searchQuery || undefined,
        location: locationFilter || undefined,
        employmentType: typeFilter || undefined,
        isActive: true,
        pageSize: 12
      }, token);
      setVacancies(res.items);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unable to load data.');
    } finally {
      setLoading(false);
    }
  };

  const fetchCandidateState = async () => {
    try {
      const [saved] = await Promise.all([
        api.getSavedVacancies(token),
      ]);
      setSavedVacancies(saved);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unable to load data.');
    }
  };

  useEffect(() => {
    fetchVacancies();
    fetchCandidateState();
  }, [searchQuery, locationFilter, typeFilter, token]);

  const isVacancySaved = (vacancyId: number) => {
    return savedVacancies.some(sv => sv.vacancyId === vacancyId);
  };

  const handleToggleSave = async (vacancyId: number) => {
    try {
      if (isVacancySaved(vacancyId)) {
        await api.unsaveVacancy(vacancyId, token);
      } else {
        await api.saveVacancy(vacancyId, token);
      }
      fetchCandidateState();
    } catch (e) {
      alert('Failed to update bookmark');
    }
  };

  const handleApply = async (vacancyId: number) => {
    setApplying(vacancyId);
    setError('');
    try {
      await api.applyToVacancy(vacancyId, token);
      await fetchCandidateState();
      await fetchVacancies();
      if (selectedVacancy) setSelectedVacancy(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Application failed.');
    } finally {
      setApplying(null);
    }
  };

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>Available Internship Vacancies</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Browse active internship openings, check non-negotiable requirements, bookmark vacancies, and apply.
          </p>
        </div>
      </div>

      {/* Filter & Search Toolbar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '24px', display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '8px 12px', flex: '1 1 240px' }}>
          <Search size={16} style={{ color: 'var(--text-secondary)', marginRight: '8px' }} />
          <input
            type="text"
            placeholder="Search vacancies, technologies..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            style={{ background: 'transparent', border: 'none', color: '#fff', width: '100%', outline: 'none' }}
          />
        </div>

        <select
          value={locationFilter}
          onChange={e => setLocationFilter(e.target.value)}
          style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', padding: '8px 12px', borderRadius: '8px' }}
        >
          <option value="" style={{ background: '#131b2e', color: '#f8fafc' }}>All Locations</option>
          <option value="Colombo" style={{ background: '#131b2e', color: '#f8fafc' }}>Colombo</option>
          <option value="Kandy" style={{ background: '#131b2e', color: '#f8fafc' }}>Kandy</option>
          <option value="Remote" style={{ background: '#131b2e', color: '#f8fafc' }}>Remote</option>
        </select>

        <select
          value={typeFilter}
          onChange={e => setTypeFilter(e.target.value)}
          style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', padding: '8px 12px', borderRadius: '8px' }}
        >
          <option value="" style={{ background: '#131b2e', color: '#f8fafc' }}>All Job Types</option>
          <option value="Internship" style={{ background: '#131b2e', color: '#f8fafc' }}>Internship</option>
          <option value="FullTime" style={{ background: '#131b2e', color: '#f8fafc' }}>Full-Time</option>
          <option value="PartTime" style={{ background: '#131b2e', color: '#f8fafc' }}>Part-Time</option>
        </select>
      </div>

      {error && <p role="alert">{error}</p>}
      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          Loading vacancies...
        </div>
      ) : vacancies.length === 0 ? (
        <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          No active vacancies found.
        </div>
      ) : (
        <div className="cards-grid">
          {vacancies.map(v => {
            const isApplied = v.hasApplied || !!v.currentApplicationStatus;
            const saved = isVacancySaved(v.id);

            return (
              <div key={v.id} className="glass-panel" style={{ padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                    <h3 style={{ fontSize: '18px', fontWeight: 700 }}>{v.title}</h3>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span className="status-badge status-approved">{v.employmentType}</span>
                      <button
                        onClick={() => handleToggleSave(v.id)}
                        title={saved ? 'Remove Bookmark' : 'Save Vacancy'}
                        style={{ background: 'none', border: 'none', color: saved ? '#818cf8' : 'var(--text-secondary)', cursor: 'pointer', padding: '4px' }}
                      >
                        {saved ? <BookmarkCheck size={20} /> : <Bookmark size={20} />}
                      </button>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '16px', color: 'var(--text-secondary)', fontSize: '13px', marginBottom: '16px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Building2 size={14} />
                      <span>{v.companyName || v.company?.name || 'TechCorp Solutions'}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <MapPin size={14} />
                      <span>{v.location}</span>
                    </div>
                  </div>

                  <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '20px', minHeight: '40px' }}>
                    {v.description}
                  </p>

                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '20px' }}>
                    {v.skills && v.skills.length > 0 ? (
                      v.skills.map(sk => (
                        <span key={sk.skillId} style={{ background: 'rgba(255, 255, 255, 0.05)', border: '1px solid var(--border-color)', padding: '4px 10px', borderRadius: '6px', fontSize: '12px' }}>
                          {sk.skillName}
                        </span>
                      ))
                    ) : (
                      <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Software Engineering Skills</span>
                    )}
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '10px', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap' }}>
                  <button className="btn-secondary" style={{ flex: '0 0 auto', width: 'auto', fontSize: '13px' }} onClick={() => setSelectedVacancy(v)}>
                    <Info size={14} /> Details
                  </button>

                  {isApplied ? (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', background: 'rgba(16, 185, 129, 0.15)', padding: '8px 12px', borderRadius: '8px', border: '1px solid rgba(16, 185, 129, 0.3)', color: '#10b981', fontSize: '12px', fontWeight: 600 }}>
                      <CheckCircle2 size={16} /> {v.currentApplicationStatus === 'WITHDRAWN' ? 'Withdrawn' : 'Applied'}
                    </div>
                  ) : (
                    <button className="btn-action btn-approve" style={{ flex: '0 0 auto', width: 'auto', fontSize: '13px' }} disabled={applying !== null} onClick={() => handleApply(v.id)}>
                      <Send size={14} /> Apply
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Vacancy Details Modal */}
      {selectedVacancy && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '90%', maxWidth: '650px', padding: '24px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
              <div>
                <h2 style={{ fontSize: '22px', fontWeight: 700 }}>{selectedVacancy.title}</h2>
                <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>
                  {selectedVacancy.companyName || selectedVacancy.company?.name} - {selectedVacancy.location} ({selectedVacancy.employmentType})
                </p>
              </div>
              <button className="btn-secondary" onClick={() => setSelectedVacancy(null)}>Close</button>
            </div>

            <div style={{ marginBottom: '20px' }}>
              <h4 style={{ fontSize: '14px', fontWeight: 700, marginBottom: '6px', color: 'var(--text-secondary)' }}>Description</h4>
              <p style={{ fontSize: '14px', lineHeight: '1.5' }}>{selectedVacancy.description}</p>
            </div>

            <div style={{ marginBottom: '20px' }}>
              <h4 style={{ fontSize: '14px', fontWeight: 700, marginBottom: '8px', color: 'var(--text-secondary)' }}>Required Skills Taxonomy</h4>
              <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                {(selectedVacancy.skills?.length ? selectedVacancy.skills : (selectedVacancy.vacancySkills ?? []).map(vs => ({ skillId: undefined, skillName: vs.skill?.name, isMandatory: vs.isMandatory }))).map((sk, index) => (
                  <span key={sk.skillId ?? index} style={{ background: sk.isMandatory ? 'rgba(129, 140, 248, 0.15)' : 'rgba(255, 255, 255, 0.05)', border: `1px solid ${sk.isMandatory ? '#818cf8' : 'var(--border-color)'}`, padding: '6px 12px', borderRadius: '6px', fontSize: '13px' }}>
                    {sk.skillName} {sk.isMandatory ? '(Mandatory)' : '(Preferred)'}
                  </span>
                ))}
              </div>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <h4 style={{ fontSize: '14px', fontWeight: 700, marginBottom: '8px', color: '#ef4444' }}>Non-Negotiable Eligibility Requirements</h4>
              {selectedVacancy.requirements && selectedVacancy.requirements.length > 0 ? (
                <ul style={{ paddingLeft: '20px', fontSize: '13px', color: 'var(--text-secondary)' }}>
                  {selectedVacancy.requirements.map(req => (
                    <li key={req.id} style={{ marginBottom: '4px' }}>
                      {req.requirementText} {req.isNonNegotiable && <strong style={{ color: '#ef4444' }}>(Non-Negotiable)</strong>}
                    </li>
                  ))}
                </ul>
              ) : (
                <p style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Must possess relevant background and skills.</p>
              )}
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button className="btn-secondary" onClick={() => setSelectedVacancy(null)}>Close</button>
              {!selectedVacancy.currentApplicationStatus && !selectedVacancy.hasApplied && (
                <button className="btn-action btn-approve" disabled={applying !== null} onClick={() => handleApply(selectedVacancy.id)}>
                  <Send size={16} /> Confirm Application
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
