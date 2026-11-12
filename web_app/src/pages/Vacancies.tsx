import { useAuth } from '../context/AuthContext';
import React, { useEffect, useState } from 'react';
import { api, type Vacancy, type Company, type Application, type EligibilityResult } from '../services/api';
import { MapPin, Building2, Plus, Search, Eye, CheckCircle2, ToggleLeft, ToggleRight, Sparkles } from 'lucide-react';

export const Vacancies: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? "";
  const [vacancies, setVacancies] = useState<Vacancy[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(true);

  // Filter & Pagination State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLocation, setSelectedLocation] = useState('');
  const [selectedType, setSelectedType] = useState('');
  const [selectedCompany, setSelectedCompany] = useState<number | ''>('');
  const [showInactive, setShowInactive] = useState(false);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  // Modal States
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showApplicationsModal, setShowApplicationsModal] = useState(false);
  const [selectedVacancyForPipeline, setSelectedVacancyForPipeline] = useState<Vacancy | null>(null);
  const [pipelineApplications, setPipelineApplications] = useState<Application[]>([]);
  const [eligibilityResult, setEligibilityResult] = useState<EligibilityResult | null>(null);
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  // Form State for New Vacancy
  const [newTitle, setNewTitle] = useState('');
  const [newDesc, setNewDesc] = useState('');
  const [newLoc, setNewLoc] = useState('Colombo');
  const [newType, setNewType] = useState('Internship');
  const [newCompanyId, setNewCompanyId] = useState<number>(1);
  const [newSkills, setNewSkills] = useState('React, SQL, Git');
  const [newRequirements, setNewRequirements] = useState('Currently pursuing CS/SE degree');

  const fetchVacancies = async () => {
    setLoading(true);
    try {
      const res = await api.getVacanciesAdvanced({
        searchQuery: searchQuery || undefined,
        location: selectedLocation || undefined,
        employmentType: selectedType || undefined,
        companyId: selectedCompany ? Number(selectedCompany) : undefined,
        isActive: showInactive ? undefined : true,
        page,
        pageSize: 6
      }, token);
      setVacancies(res.items);
      setTotalPages(res.totalPages || 1);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const fetchCompanies = async () => {
    try {
      const data = await api.getCompanies(token);
      setCompanies(data);
      if (data.length > 0) setNewCompanyId(data[0].id);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    fetchCompanies();
  }, [token]);

  useEffect(() => {
    fetchVacancies();
  }, [searchQuery, selectedLocation, selectedType, selectedCompany, showInactive, page]);

  const handleCreateVacancy = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim() || !newDesc.trim()) return;

    try {
      const skillsArray = newSkills.split(',').map(s => s.trim()).filter(Boolean).map(name => ({
        skillName: name,
        isMandatory: true
      }));

      const reqsArray = newRequirements.split('\n').map(r => r.trim()).filter(Boolean).map(text => ({
        requirementText: text,
        isNonNegotiable: true
      }));

      await api.createVacancy({
        title: newTitle,
        description: newDesc,
        location: newLoc,
        employmentType: newType,
        companyId: newCompanyId,
        skills: skillsArray,
        requirements: reqsArray
      }, token);

      setShowCreateModal(false);
      setNewTitle('');
      setNewDesc('');
      setActionMessage('Vacancy published successfully!');
      fetchVacancies();
      setTimeout(() => setActionMessage(null), 3000);
    } catch (err: any) {
      alert(err.message || 'Failed to create vacancy');
    }
  };

  const handleToggleStatus = async (id: number) => {
    try {
      await api.toggleVacancyStatus(id, token);
      fetchVacancies();
    } catch (err: any) {
      alert('Failed to update vacancy status');
    }
  };

  const handleOpenPipeline = async (v: Vacancy) => {
    setSelectedVacancyForPipeline(v);
    setShowApplicationsModal(true);
    setEligibilityResult(null);
    try {
      const apps = await api.getVacancyApplications(v.id, token);
      setPipelineApplications(apps);
    } catch (e) {
      console.error(e);
    }
  };

  const handleRunEligibilityCheck = async (appId: number) => {
    try {
      const res = await api.performEligibilityCheck(appId, token);
      setEligibilityResult(res);
      if (selectedVacancyForPipeline) {
        const updated = await api.getVacancyApplications(selectedVacancyForPipeline.id, token);
        setPipelineApplications(updated);
      }
    } catch (err) {
      alert('Eligibility check failed');
    }
  };

  const handleRunAiMatch = async (appId: number) => {
    try {
      await api.evaluateApplicationMatch(appId, token);
      if (selectedVacancyForPipeline) {
        const updated = await api.getVacancyApplications(selectedVacancyForPipeline.id, token);
        setPipelineApplications(updated);
      }
      setActionMessage('Agentic AI matching executed!');
      setTimeout(() => setActionMessage(null), 3000);
    } catch (err) {
      alert('AI Evaluation failed');
    }
  };

  return (
    <div>
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '28px', fontWeight: 700 }}>Vacancy & Internship Management</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px' }}>
            Publish, filter, and manage internship vacancies and candidate application pipelines.
          </p>
        </div>

        <button className="btn-action btn-approve" onClick={() => setShowCreateModal(true)}>
          <Plus size={18} />
          Create New Vacancy
        </button>
      </div>

      {actionMessage && (
        <div style={{ background: 'rgba(16, 185, 129, 0.15)', border: '1px solid #10b981', color: '#10b981', padding: '12px 16px', borderRadius: '8px', marginBottom: '20px' }}>
          {actionMessage}
        </div>
      )}

      {/* Filter & Search Toolbar */}
      <div className="glass-panel" style={{ padding: '16px', marginBottom: '24px', display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', borderRadius: '8px', padding: '8px 12px', flex: '1 1 240px' }}>
          <Search size={16} style={{ color: 'var(--text-secondary)', marginRight: '8px' }} />
          <input
            type="text"
            placeholder="Search by title, description..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            style={{ background: 'transparent', border: 'none', color: '#fff', width: '100%', outline: 'none' }}
          />
        </div>

        <select
          value={selectedLocation}
          onChange={e => setSelectedLocation(e.target.value)}
          style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', padding: '8px 12px', borderRadius: '8px' }}
        >
          <option value="" style={{ background: '#131b2e', color: '#f8fafc' }}>All Locations</option>
          <option value="Colombo" style={{ background: '#131b2e', color: '#f8fafc' }}>Colombo</option>
          <option value="Kandy" style={{ background: '#131b2e', color: '#f8fafc' }}>Kandy</option>
          <option value="Remote" style={{ background: '#131b2e', color: '#f8fafc' }}>Remote</option>
        </select>

        <select
          value={selectedType}
          onChange={e => setSelectedType(e.target.value)}
          style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', padding: '8px 12px', borderRadius: '8px' }}
        >
          <option value="" style={{ background: '#131b2e', color: '#f8fafc' }}>All Job Types</option>
          <option value="Internship" style={{ background: '#131b2e', color: '#f8fafc' }}>Internship</option>
          <option value="FullTime" style={{ background: '#131b2e', color: '#f8fafc' }}>Full-Time</option>
          <option value="PartTime" style={{ background: '#131b2e', color: '#f8fafc' }}>Part-Time</option>
        </select>

        <select
          value={selectedCompany}
          onChange={e => setSelectedCompany(e.target.value ? Number(e.target.value) : '')}
          style={{ background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', padding: '8px 12px', borderRadius: '8px' }}
        >
          <option value="" style={{ background: '#131b2e', color: '#f8fafc' }}>All Companies</option>
          {companies.map(c => (
            <option key={c.id} value={c.id} style={{ background: '#131b2e', color: '#f8fafc' }}>{c.name}</option>
          ))}
        </select>

        <button
          className="btn-secondary"
          onClick={() => setShowInactive(!showInactive)}
          style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}
        >
          {showInactive ? <ToggleRight color="#10b981" /> : <ToggleLeft color="#6b7280" />}
          Include Inactive
        </button>
      </div>

      {/* Vacancy Cards Grid */}
      {loading ? (
        <div style={{ textTransform: 'uppercase', letterSpacing: '1px', padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          Loading vacancies...
        </div>
      ) : vacancies.length === 0 ? (
        <div className="glass-panel" style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
          No vacancies found matching your search criteria.
        </div>
      ) : (
        <div className="cards-grid">
          {vacancies.map(v => (
            <div key={v.id} className="glass-panel" style={{ padding: '24px', opacity: v.isActive ? 1 : 0.65 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px' }}>
                <h3 style={{ fontSize: '18px', fontWeight: 700 }}>{v.title}</h3>
                <span className={`status-badge ${v.isActive ? 'status-approved' : 'status-rejected'}`}>
                  {v.isActive ? v.employmentType : 'Inactive'}
                </span>
              </div>

              <div style={{ display: 'flex', gap: '16px', color: 'var(--text-secondary)', fontSize: '13px', marginBottom: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Building2 size={14} />
                  <span>{v.companyName || v.company?.name || 'TechCorp'}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <MapPin size={14} />
                  <span>{v.location}</span>
                </div>
              </div>

              <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '20px', minHeight: '40px' }}>
                {v.description}
              </p>

              {/* Skills */}
              <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '16px' }}>
                {v.skills && v.skills.length > 0 ? (
                  v.skills.map(sk => (
                    <span key={sk.skillId} style={{ background: 'rgba(255, 255, 255, 0.05)', border: '1px solid var(--border-color)', padding: '4px 10px', borderRadius: '6px', fontSize: '12px' }}>
                      {sk.skillName} {sk.isMandatory && '*(Req)'}
                    </span>
                  ))
                ) : (
                  <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>General Software Skills</span>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-color)', paddingTop: '16px', marginTop: '16px' }}>
                <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                  Applications: <strong>{v.applicationCount ?? 0}</strong>
                </span>

                <div style={{ display: 'flex', gap: '8px' }}>
                  <button className="btn-secondary" style={{ padding: '6px 12px', fontSize: '12px' }} onClick={() => handleToggleStatus(v.id)}>
                    {v.isActive ? 'Deactivate' : 'Activate'}
                  </button>

                  <button className="btn-action btn-approve" style={{ padding: '6px 12px', fontSize: '12px' }} onClick={() => handleOpenPipeline(v)}>
                    <Eye size={14} /> Pipeline
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Pagination Bar */}
      {totalPages > 1 && (
        <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', marginTop: '24px' }}>
          <button className="btn-secondary" disabled={page <= 1} onClick={() => setPage(page - 1)}>Previous</button>
          <span style={{ padding: '8px 12px', color: 'var(--text-secondary)' }}>Page {page} of {totalPages}</span>
          <button className="btn-secondary" disabled={page >= totalPages} onClick={() => setPage(page + 1)}>Next</button>
        </div>
      )}

      {/* Create Vacancy Modal */}
      {showCreateModal && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '90%', maxWidth: '600px', padding: '24px', maxHeight: '90vh', overflowY: 'auto' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '16px' }}>Publish New Internship Vacancy</h2>

            <form onSubmit={handleCreateVacancy}>
              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Company</label>
                <select value={newCompanyId} onChange={e => setNewCompanyId(Number(e.target.value))} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', borderRadius: '6px' }}>
                  {companies.map(c => <option key={c.id} value={c.id} style={{ background: '#131b2e', color: '#f8fafc' }}>{c.name} ({c.location})</option>)}
                </select>
              </div>

              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Job Title</label>
                <input type="text" required value={newTitle} onChange={e => setNewTitle(e.target.value)} placeholder="e.g. Software Engineering Intern" style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div className="responsive-grid-2" style={{ gap: '12px', marginBottom: '12px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Location</label>
                  <input type="text" value={newLoc} onChange={e => setNewLoc(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Employment Type</label>
                  <select value={newType} onChange={e => setNewType(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.08)', border: '1px solid var(--border-color)', color: '#f8fafc', borderRadius: '6px' }}>
                    <option value="Internship" style={{ background: '#131b2e', color: '#f8fafc' }}>Internship</option>
                    <option value="FullTime" style={{ background: '#131b2e', color: '#f8fafc' }}>Full-Time</option>
                    <option value="PartTime" style={{ background: '#131b2e', color: '#f8fafc' }}>Part-Time</option>
                  </select>
                </div>
              </div>

              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Description</label>
                <textarea required rows={3} value={newDesc} onChange={e => setNewDesc(e.target.value)} placeholder="Vacancy responsibilities..." style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ marginBottom: '12px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Mandatory Skills (Comma separated)</label>
                <input type="text" value={newSkills} onChange={e => setNewSkills(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ marginBottom: '20px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '4px' }}>Non-Negotiable Requirements (One per line)</label>
                <textarea rows={2} value={newRequirements} onChange={e => setNewRequirements(e.target.value)} style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', borderRadius: '6px' }} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-secondary" onClick={() => setShowCreateModal(false)}>Cancel</button>
                <button type="submit" className="btn-action btn-approve">Publish Vacancy</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Applications Pipeline Modal */}
      {showApplicationsModal && selectedVacancyForPipeline && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="glass-panel" style={{ width: '90%', maxWidth: '800px', padding: '24px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h2 style={{ fontSize: '20px', fontWeight: 700 }}>Applications Pipeline</h2>
                <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>{selectedVacancyForPipeline.title}</p>
              </div>
              <button className="btn-secondary" onClick={() => setShowApplicationsModal(false)}>Close</button>
            </div>

            {eligibilityResult && (
              <div style={{ background: eligibilityResult.isEligible ? 'rgba(16, 185, 129, 0.15)' : 'rgba(239, 68, 68, 0.15)', border: `1px solid ${eligibilityResult.isEligible ? '#10b981' : '#ef4444'}`, padding: '16px', borderRadius: '8px', marginBottom: '20px' }}>
                <h4 style={{ fontSize: '14px', fontWeight: 700, color: eligibilityResult.isEligible ? '#10b981' : '#ef4444', marginBottom: '6px' }}>
                  Member 2 Non-Negotiable Eligibility Check: {eligibilityResult.isEligible ? 'PASSED' : 'FAILED'}
                </h4>
                <p style={{ fontSize: '13px', color: '#fff' }}>{eligibilityResult.summaryNotes}</p>
              </div>
            )}

            {pipelineApplications.length === 0 ? (
              <div style={{ padding: '30px', textAlign: 'center', color: 'var(--text-secondary)' }}>
                No candidate applications submitted for this vacancy yet.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {pipelineApplications.map(app => (
                  <div key={app.id} style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-color)', padding: '16px', borderRadius: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <h4 style={{ fontWeight: 700 }}>{app.candidateName || `Candidate #${app.candidateId}`}</h4>
                        <span className={`status-badge status-${app.status.toLowerCase().replace(/_/g, '-')}`}>
                          {app.status}
                        </span>
                      </div>
                      <p style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                        Applied: {new Date(app.appliedAt).toLocaleDateString()} | Match Score: {app.matchScore}%
                      </p>
                    </div>

                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button className="btn-secondary" style={{ fontSize: '12px', padding: '6px 10px' }} onClick={() => handleRunEligibilityCheck(app.id)}>
                        <CheckCircle2 size={14} /> Check Eligibility
                      </button>

                      <button className="btn-action btn-approve" style={{ fontSize: '12px', padding: '6px 10px' }} onClick={() => handleRunAiMatch(app.id)}>
                        <Sparkles size={14} /> AI Match
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
