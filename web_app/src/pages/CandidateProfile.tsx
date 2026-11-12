import React, { useState, useEffect, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import type {
  CandidateProfileDto,
  CandidateSkillDto,
  SkillDto,
  EducationDto,
  ExperienceDto,
  CVDocumentDto,
  CertificateDto,
  ProfileCompletenessDto,
  CreateEducationDto,
  CreateExperienceDto,
  CreateCertificateDto,
} from '../services/api';
import {
  User,
  Code2,
  GraduationCap,
  Briefcase,
  Settings,
  FileText,
  Award,
  ShieldCheck,
  Plus,
  Trash2,
  Edit3,
  Save,
  X,
  UploadCloud,
  CheckCircle,
  AlertTriangle,
  Loader2,
  MapPin,
  Phone,
  Link,
  Calendar,
} from 'lucide-react';

// ─── Utility ──────────────────────────────────────────────────────────────────
const fmtDate = (d?: string) => (d ? d.slice(0, 10) : '');

const inputStyle: React.CSSProperties = {
  width: '100%',
  padding: '10px 14px',
  borderRadius: '8px',
  background: 'rgba(255,255,255,0.05)',
  border: '1px solid var(--border-color)',
  color: '#fff',
  fontSize: '14px',
  boxSizing: 'border-box',
};

const labelStyle: React.CSSProperties = {
  display: 'block',
  color: 'var(--text-secondary)',
  fontSize: '12px',
  marginBottom: '5px',
  textTransform: 'uppercase',
  letterSpacing: '0.05em',
};

// ─── Completeness Widget ──────────────────────────────────────────────────────
const CompletenessWidget: React.FC<{ data: ProfileCompletenessDto; onRefresh: () => void }> = ({
  data,
  onRefresh,
}) => {
  const pct = data.completionPercentage ?? data.profileScorePercentage ?? 0;
  const color = pct === 100 ? '#10b981' : pct >= 67 ? '#f59e0b' : '#ef4444';
  return (
    <div
      className="glass-panel"
      style={{ padding: '20px', marginBottom: '24px', borderLeft: `4px solid ${color}` }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          {pct === 100 ? (
            <CheckCircle size={22} color="#10b981" />
          ) : (
            <AlertTriangle size={22} color={color} />
          )}
          <div>
            <span style={{ fontWeight: 700, fontSize: '15px' }}>Profile Completeness: </span>
            <span style={{ fontWeight: 800, fontSize: '18px', color }}>{pct}%</span>
            <div style={{ fontSize: '12px' }}>
              {(data.completedFields ?? []).length} of {(data.completedFields ?? []).length + data.missingFields.length} mandatory profile requirements completed. This measures data completeness, not vacancy suitability.
            </div>
          </div>
        </div>
        <button
          onClick={onRefresh}
          style={{
            background: 'rgba(99,102,241,0.15)',
            color: '#818cf8',
            border: '1px solid rgba(99,102,241,0.4)',
            padding: '6px 14px',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '12px',
            fontWeight: 600,
          }}
        >
          <ShieldCheck size={14} style={{ display: 'inline', marginRight: '5px' }} />
          Re-check
        </button>
      </div>

      <div
        style={{
          height: '8px',
          borderRadius: '4px',
          background: 'rgba(255,255,255,0.08)',
          overflow: 'hidden',
          marginBottom: '10px',
        }}
      >
        <div
          style={{
            height: '100%',
            width: `${pct}%`,
            background: `linear-gradient(90deg, ${color}, ${color}aa)`,
            borderRadius: '4px',
            transition: 'width 0.6s ease',
          }}
        />
      </div>

      {data.missingFields.length > 0 && (
        <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>
          <span style={{ fontWeight: 600, color: '#f59e0b' }}>Missing: </span>
          {data.missingFields.join(', ')}
        </div>
      )}
      {pct === 100 && (
        <div style={{ fontSize: '13px', color: '#10b981', fontWeight: 600 }}>
          ✓ All mandatory fields complete — you can apply to vacancies!
        </div>
      )}
    </div>
  );
};

// ─── Tab: Personal Details ────────────────────────────────────────────────────
const ProfileTab: React.FC<{
  profile: CandidateProfileDto;
  candidateId: number;
  token: string;
  onSaved: (p: CandidateProfileDto) => void;
}> = ({ profile, candidateId, token, onSaved }) => {
  const [form, setForm] = useState({
    phone: profile.phone ?? '',
    city: profile.city ?? '',
    bio: profile.bio ?? '',
    linkedInUrl: profile.linkedInUrl ?? '',
    portfolioUrl: profile.portfolioUrl ?? '',
  });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');

  const handleSave = async () => {
    setSaving(true);
    setError('');
    try {
      const updated = await api.updateCandidateProfile(candidateId, form, token);
      onSaved(updated);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
      {/* Left column */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div>
          <label style={labelStyle}>Full Name</label>
          <input style={{ ...inputStyle, opacity: 0.5, cursor: 'not-allowed' }} value={profile.fullName} disabled />
        </div>
        <div>
          <label style={labelStyle}>Email</label>
          <input style={{ ...inputStyle, opacity: 0.5, cursor: 'not-allowed' }} value={profile.email} disabled />
        </div>
        <div>
          <label style={labelStyle}>
            <Phone size={12} style={{ display: 'inline', marginRight: '4px' }} />
            Phone Number *
          </label>
          <input
            style={inputStyle}
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
            placeholder="+94 77 123 4567"
          />
        </div>
        <div>
          <label style={labelStyle}>
            <MapPin size={12} style={{ display: 'inline', marginRight: '4px' }} />
            City / Location *
          </label>
          <input
            style={inputStyle}
            value={form.city}
            onChange={(e) => setForm({ ...form, city: e.target.value })}
            placeholder="Colombo, Sri Lanka"
          />
        </div>
      </div>

      {/* Right column */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
            <label style={{ ...labelStyle, marginBottom: 0 }}>Bio / Summary *</label>
            <span style={{ fontSize: '11px', color: form.bio.length > 1900 ? '#ef4444' : 'var(--text-secondary)' }}>
              {form.bio.length}/2000
            </span>
          </div>
          <textarea
            style={{ ...inputStyle, height: '100px', resize: 'vertical' }}
            value={form.bio}
            maxLength={2000}
            onChange={(e) => setForm({ ...form, bio: e.target.value })}
            placeholder="A brief professional summary..."
          />
        </div>
        <div>
          <label style={labelStyle}>
            <Link size={12} style={{ display: 'inline', marginRight: '4px' }} />
            LinkedIn URL
          </label>
          <input
            style={inputStyle}
            value={form.linkedInUrl}
            onChange={(e) => setForm({ ...form, linkedInUrl: e.target.value })}
            placeholder="https://linkedin.com/in/..."
          />
        </div>
        <div>
          <label style={labelStyle}>Portfolio URL</label>
          <input
            style={inputStyle}
            value={form.portfolioUrl}
            onChange={(e) => setForm({ ...form, portfolioUrl: e.target.value })}
            placeholder="https://yourportfolio.dev"
          />
        </div>
      </div>

      {/* Footer */}
      <div style={{ gridColumn: '1 / -1', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <button
          className="btn-action btn-approve"
          onClick={handleSave}
          disabled={saving}
          style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
        >
          {saving ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
          {saving ? 'Saving…' : 'Save Changes'}
        </button>
        {saved && (
          <span style={{ color: '#10b981', fontSize: '13px', fontWeight: 600 }}>
            <CheckCircle size={14} style={{ display: 'inline', marginRight: '4px' }} />
            Saved!
          </span>
        )}
        {error && <span style={{ color: '#ef4444', fontSize: '13px' }}>{error}</span>}
      </div>
    </div>
  );
};

// ─── Tab: Skills ──────────────────────────────────────────────────────────────
const SkillsTab: React.FC<{
  candidateId: number;
  token: string;
  onChanged: () => void;
}> = ({ candidateId, token, onChanged }) => {
  const [skills, setSkills] = useState<CandidateSkillDto[]>([]);
  const [taxonomy, setTaxonomy] = useState<SkillDto[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [adding, setAdding] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    const [s, t] = await Promise.all([
      api.getCandidateSkills(candidateId, token).catch(() => [] as CandidateSkillDto[]),
      api.getAllSkills(token).catch(() => [] as SkillDto[]),
    ]);
    setSkills(s);
    setTaxonomy(t);
    setLoading(false);
  };

  useEffect(() => { load(); }, [candidateId]);

  const ownedIds = new Set(skills.map((s) => s.skillId));
  const trimmedSearch = search.trim();
  const filtered = taxonomy.filter(
    (t) => !ownedIds.has(t.id) && t.name.toLowerCase().includes(trimmedSearch.toLowerCase())
  );

  // True when the typed name doesn't match any existing taxonomy skill (case-insensitive)
  const noExactMatch = trimmedSearch.length > 0 &&
    !taxonomy.some((t) => t.name.toLowerCase() === trimmedSearch.toLowerCase());

  const handleAdd = async (skillId: number) => {
    setAdding(true);
    setError('');
    try {
      await api.addCandidateSkill(candidateId, { skillId }, token);
      await load();
      onChanged();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setAdding(false);
    }
  };

  // Create new taxonomy skill (idempotent) then attach to candidate
  const handleCreateAndAdd = async () => {
    if (!trimmedSearch) return;
    setAdding(true);
    setError('');
    try {
      const created = await api.createSkill({ name: trimmedSearch, category: 'General' }, token);
      await api.addCandidateSkill(candidateId, { skillId: created.id }, token);
      setSearch('');
      await load();
      onChanged();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setAdding(false);
    }
  };

  const handleRemove = async (skillId: number) => {
    try {
      await api.removeCandidateSkill(candidateId, skillId, token);
      await load();
      onChanged();
    } catch (e: any) {
      setError(e.message);
    }
  };

  if (loading) return <div style={{ color: 'var(--text-secondary)', padding: '20px' }}>Loading skills…</div>;

  return (
    <div>
      {error && (
        <div style={{ color: '#ef4444', background: 'rgba(239,68,68,0.1)', padding: '10px 14px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px' }}>
          {error}
        </div>
      )}

      {/* Current skills */}
      <div style={{ marginBottom: '24px' }}>
        <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>
          Your Skills ({skills.length})
        </h4>
        {skills.length === 0 ? (
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>No skills added yet. Add from the taxonomy below.</p>
        ) : (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
            {skills.map((s) => (
              <span
                key={s.id}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  background: 'rgba(99,102,241,0.15)',
                  color: '#818cf8',
                  border: '1px solid rgba(99,102,241,0.4)',
                  padding: '6px 12px',
                  borderRadius: '20px',
                  fontSize: '13px',
                  fontWeight: 600,
                }}
              >
                {s.skillName}
                {s.category && (
                  <span style={{ fontSize: '10px', opacity: 0.6 }}>({s.category})</span>
                )}
                <button
                  onClick={() => handleRemove(s.skillId)}
                  style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0, color: '#ef4444', display: 'flex', alignItems: 'center' }}
                  title="Remove skill"
                >
                  <X size={12} />
                </button>
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Taxonomy picker */}
      <div>
        <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>
          Add from Skill Taxonomy
        </h4>
        <input
          style={{ ...inputStyle, marginBottom: '12px' }}
          placeholder="Search skills… (e.g. Python, React)"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', maxHeight: '200px', overflowY: 'auto' }}>
          {filtered.map((t) => (
            <button
              key={t.id}
              onClick={() => handleAdd(t.id)}
              disabled={adding}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                background: 'rgba(6,182,212,0.08)',
                color: '#22d3ee',
                border: '1px solid rgba(6,182,212,0.3)',
                padding: '6px 12px',
                borderRadius: '20px',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
              }}
            >
              <Plus size={12} />
              {t.name}
            </button>
          ))}

          {/* Custom skill — shown only when typed name has no exact taxonomy match */}
          {noExactMatch && (
            <button
              onClick={handleCreateAndAdd}
              disabled={adding}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                background: 'rgba(16,185,129,0.10)',
                color: '#34d399',
                border: '1px dashed rgba(16,185,129,0.5)',
                padding: '6px 14px',
                borderRadius: '20px',
                fontSize: '13px',
                fontWeight: 700,
                cursor: adding ? 'not-allowed' : 'pointer',
                opacity: adding ? 0.6 : 1,
              }}
              title={`Create new skill "${trimmedSearch}" and add to your profile`}
            >
              <Plus size={12} />
              {adding ? 'Adding…' : `Add "${trimmedSearch}"`}
            </button>
          )}
        </div>
        {filtered.length === 0 && !noExactMatch && (
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '8px' }}>
            {trimmedSearch ? 'All matching skills already in your profile.' : 'All available skills already added.'}
          </p>
        )}
      </div>
    </div>
  );
};

// ─── Tab: Education ───────────────────────────────────────────────────────────
const EducationTab: React.FC<{
  candidateId: number;
  token: string;
  onChanged: () => void;
}> = ({ candidateId, token, onChanged }) => {
  const currentYear = new Date().getFullYear();
  const [items, setItems] = useState<EducationDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const blank: CreateEducationDto = {
    institution: '',
    degree: '',
    fieldOfStudy: '',
    startYear: currentYear - 4,
    endYear: currentYear,
  };
  const [form, setForm] = useState<CreateEducationDto>(blank);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    const data = await api.getEducations(candidateId, token).catch(() => [] as EducationDto[]);
    setItems(data);
    setLoading(false);
  };

  useEffect(() => { load(); }, [candidateId]);

  const openAdd = () => { setForm(blank); setEditId(null); setShowForm(true); setError(''); };
  const openEdit = (e: EducationDto) => {
    setForm({
      institution: e.institution,
      degree: e.degree,
      fieldOfStudy: e.fieldOfStudy ?? '',
      startYear: e.startYear,
      endYear: e.endYear,
    });
    setEditId(e.id);
    setShowForm(true);
    setError('');
  };

  const handleSave = async () => {
    if (!form.institution.trim()) {
      setError('Institution is required.');
      return;
    }
    if (!form.degree.trim()) {
      setError('Degree / Qualification is required.');
      return;
    }
    const startYearNum = Number(form.startYear);
    const endYearNum = Number(form.endYear);
    if (isNaN(startYearNum) || startYearNum < 1950 || startYearNum > 2100) {
      setError('Start Year must be a valid year between 1950 and 2100.');
      return;
    }
    if (isNaN(endYearNum) || endYearNum < 1950 || endYearNum > 2100) {
      setError('End Year must be a valid year between 1950 and 2100.');
      return;
    }
    if (endYearNum < startYearNum) {
      setError('End Year must be greater than or equal to Start Year.');
      return;
    }

    setSaving(true);
    setError('');

    const payload: CreateEducationDto = {
      institution: form.institution.trim(),
      degree: form.degree.trim(),
      fieldOfStudy: form.fieldOfStudy?.trim() || '',
      startYear: startYearNum,
      endYear: endYearNum,
    };

    try {
      if (editId !== null) {
        await api.updateEducation(candidateId, editId, payload, token);
      } else {
        await api.addEducation(candidateId, payload, token);
      }
      await load();
      onChanged();
      setShowForm(false);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('Delete this education record?')) return;
    await api.deleteEducation(candidateId, id, token).catch(() => {});
    await load();
    onChanged();
  };

  if (loading) return <div style={{ color: 'var(--text-secondary)', padding: '20px' }}>Loading…</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          Education History ({items.length})
        </h4>
        {!showForm && (
          <button className="btn-action btn-approve" onClick={openAdd} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '8px 14px' }}>
            <Plus size={15} /> Add Education
          </button>
        )}
      </div>

      {showForm && (
        <div className="glass-panel" style={{ padding: '20px', marginBottom: '20px' }}>
          <h5 style={{ fontWeight: 700, marginBottom: '16px' }}>{editId ? 'Edit Education' : 'Add Education'}</h5>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={labelStyle}>Institution *</label>
              <input style={inputStyle} value={form.institution} onChange={(e) => setForm({ ...form, institution: e.target.value })} placeholder="e.g. SLIIT, University of Colombo" />
            </div>
            <div>
              <label style={labelStyle}>Degree *</label>
              <input style={inputStyle} value={form.degree} onChange={(e) => setForm({ ...form, degree: e.target.value })} placeholder="e.g. BSc (Hons) in Information Technology" />
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
              <label style={labelStyle}>Field of Study</label>
              <input style={inputStyle} value={form.fieldOfStudy ?? ''} onChange={(e) => setForm({ ...form, fieldOfStudy: e.target.value })} placeholder="e.g. Software Engineering" />
            </div>
            <div>
              <label style={labelStyle}>Start Year *</label>
              <input type="number" min={1950} max={2100} style={inputStyle} value={form.startYear || ''} onChange={(e) => setForm({ ...form, startYear: parseInt(e.target.value, 10) || 0 })} placeholder="e.g. 2024" />
            </div>
            <div>
              <label style={labelStyle}>End Year *</label>
              <input type="number" min={1950} max={2100} style={inputStyle} value={form.endYear || ''} onChange={(e) => setForm({ ...form, endYear: parseInt(e.target.value, 10) || 0 })} placeholder="e.g. 2028" />
            </div>
          </div>
          {error && <div style={{ color: '#ef4444', marginTop: '10px', fontSize: '13px' }}>{error}</div>}
          <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
            <button className="btn-action btn-approve" onClick={handleSave} disabled={saving} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              {saving ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
              {saving ? 'Saving…' : 'Save'}
            </button>
            <button onClick={() => setShowForm(false)} style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--text-secondary)', border: '1px solid var(--border-color)', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer' }}>
              Cancel
            </button>
          </div>
        </div>
      )}

      {items.length === 0 && !showForm && (
        <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>No education records. Add one above to improve your profile completeness.</p>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {items.map((edu) => (
          <div key={edu.id} className="glass-panel" style={{ padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontWeight: 700, fontSize: '15px' }}>{edu.degree}</div>
              <div style={{ color: '#818cf8', fontSize: '13px', marginTop: '2px' }}>{edu.institution}</div>
              {edu.fieldOfStudy && <div style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>{edu.fieldOfStudy}</div>}
              <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Calendar size={11} />
                {edu.startYear} — {edu.endYear}
              </div>
            </div>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button onClick={() => openEdit(edu)} style={{ background: 'rgba(99,102,241,0.1)', color: '#818cf8', border: '1px solid rgba(99,102,241,0.3)', padding: '6px 10px', borderRadius: '6px', cursor: 'pointer' }}>
                <Edit3 size={14} />
              </button>
              <button onClick={() => handleDelete(edu.id)} style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.3)', padding: '6px 10px', borderRadius: '6px', cursor: 'pointer' }}>
                <Trash2 size={14} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Tab: Experience ──────────────────────────────────────────────────────────
const ExperienceTab: React.FC<{
  candidateId: number;
  token: string;
  onChanged: () => void;
}> = ({ candidateId, token, onChanged }) => {
  const [items, setItems] = useState<ExperienceDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const blank: CreateExperienceDto = { companyName: '', jobTitle: '', location: '', startDate: '', endDate: '', isCurrent: false, description: '' };
  const [form, setForm] = useState<CreateExperienceDto>(blank);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    const data = await api.getExperiences(candidateId, token).catch(() => [] as ExperienceDto[]);
    setItems(data);
    setLoading(false);
  };

  useEffect(() => { load(); }, [candidateId]);

  const openAdd = () => { setForm(blank); setEditId(null); setShowForm(true); setError(''); };
  const openEdit = (e: ExperienceDto) => {
    setForm({ companyName: e.companyName, jobTitle: e.jobTitle, location: e.location ?? '', startDate: fmtDate(e.startDate), endDate: fmtDate(e.endDate ?? ''), isCurrent: e.isCurrent, description: e.description ?? '' });
    setEditId(e.id); setShowForm(true); setError('');
  };

  const handleSave = async () => {
    setSaving(true); setError('');
    try {
      if (editId !== null) { await api.updateExperience(candidateId, editId, form, token); }
      else { await api.addExperience(candidateId, form, token); }
      await load(); onChanged(); setShowForm(false);
    } catch (e: any) { setError(e.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('Delete this experience record?')) return;
    await api.deleteExperience(candidateId, id, token).catch(() => {});
    await load(); onChanged();
  };

  if (loading) return <div style={{ color: 'var(--text-secondary)', padding: '20px' }}>Loading…</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Work Experience ({items.length})</h4>
        {!showForm && (
          <button className="btn-action btn-approve" onClick={openAdd} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '8px 14px' }}>
            <Plus size={15} /> Add Experience
          </button>
        )}
      </div>

      {showForm && (
        <div className="glass-panel" style={{ padding: '20px', marginBottom: '20px' }}>
          <h5 style={{ fontWeight: 700, marginBottom: '16px' }}>{editId ? 'Edit Experience' : 'Add Experience'}</h5>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={labelStyle}>Company Name *</label>
              <input style={inputStyle} value={form.companyName} onChange={(e) => setForm({ ...form, companyName: e.target.value })} placeholder="Google, WSO2…" />
            </div>
            <div>
              <label style={labelStyle}>Job Title *</label>
              <input style={inputStyle} value={form.jobTitle} onChange={(e) => setForm({ ...form, jobTitle: e.target.value })} placeholder="Software Engineer Intern" />
            </div>
            <div>
              <label style={labelStyle}>Location</label>
              <input style={inputStyle} value={form.location ?? ''} onChange={(e) => setForm({ ...form, location: e.target.value })} placeholder="Colombo / Remote" />
            </div>
            <div />
            <div>
              <label style={labelStyle}>Start Date *</label>
              <input type="date" style={inputStyle} value={form.startDate} onChange={(e) => setForm({ ...form, startDate: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>End Date</label>
              <input type="date" style={inputStyle} value={form.endDate ?? ''} onChange={(e) => setForm({ ...form, endDate: e.target.value })} disabled={form.isCurrent} />
              <label style={{ ...labelStyle, marginTop: '6px', display: 'flex', alignItems: 'center', gap: '6px', cursor: 'pointer' }}>
                <input type="checkbox" checked={form.isCurrent} onChange={(e) => setForm({ ...form, isCurrent: e.target.checked, endDate: e.target.checked ? '' : form.endDate })} />
                Currently working here
              </label>
            </div>
            <div style={{ gridColumn: '1 / -1' }}>
              <label style={labelStyle}>Description</label>
              <textarea style={{ ...inputStyle, height: '70px', resize: 'vertical' }} value={form.description ?? ''} onChange={(e) => setForm({ ...form, description: e.target.value })} placeholder="Key responsibilities and achievements…" />
            </div>
          </div>
          {error && <div style={{ color: '#ef4444', marginTop: '10px', fontSize: '13px' }}>{error}</div>}
          <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
            <button className="btn-action btn-approve" onClick={handleSave} disabled={saving} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              {saving ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
              {saving ? 'Saving…' : 'Save'}
            </button>
            <button onClick={() => setShowForm(false)} style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--text-secondary)', border: '1px solid var(--border-color)', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer' }}>
              Cancel
            </button>
          </div>
        </div>
      )}

      {items.length === 0 && !showForm && <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>No experience records yet.</p>}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {items.map((exp) => (
          <div key={exp.id} className="glass-panel" style={{ padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <div style={{ fontWeight: 700, fontSize: '15px' }}>{exp.jobTitle}</div>
              <div style={{ color: '#06b6d4', fontSize: '13px', marginTop: '2px' }}>{exp.companyName}</div>
              {exp.location && <div style={{ color: 'var(--text-secondary)', fontSize: '12px' }}><MapPin size={11} style={{ display: 'inline' }} /> {exp.location}</div>}
              <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Calendar size={11} />
                {fmtDate(exp.startDate)} — {exp.isCurrent ? 'Present' : fmtDate(exp.endDate ?? '')}
              </div>
              {exp.description && <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '6px', maxWidth: '460px' }}>{exp.description}</div>}
            </div>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button onClick={() => openEdit(exp)} style={{ background: 'rgba(99,102,241,0.1)', color: '#818cf8', border: '1px solid rgba(99,102,241,0.3)', padding: '6px 10px', borderRadius: '6px', cursor: 'pointer' }}>
                <Edit3 size={14} />
              </button>
              <button onClick={() => handleDelete(exp.id)} style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.3)', padding: '6px 10px', borderRadius: '6px', cursor: 'pointer' }}>
                <Trash2 size={14} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Tab: Preferences ────────────────────────────────────────────────────────
const PreferencesTab: React.FC<{ candidateId: number; token: string }> = ({ candidateId, token }) => {
  const [form, setForm] = useState({
    preferredJobType: '',
    preferredLocation: '',
    expectedStipend: '',
    preferredIndustry: '',
    isOpenToRemote: false,
    isOpenToRelocation: false,
    noticePeriodDays: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    api.getPreferences(candidateId, token).then((p) => {
      if (p) {
        setForm({
          preferredJobType: p.preferredJobType ?? '',
          preferredLocation: p.preferredLocation ?? '',
          expectedStipend: p.expectedStipend != null ? String(p.expectedStipend) : '',
          preferredIndustry: p.preferredIndustry ?? '',
          isOpenToRemote: p.isOpenToRemote,
          isOpenToRelocation: p.isOpenToRelocation,
          noticePeriodDays: p.noticePeriodDays != null ? String(p.noticePeriodDays) : '',
        });
      }
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [candidateId]);

  const handleSave = async () => {
    setSaving(true); setError('');
    try {
      await api.updatePreferences(candidateId, {
        preferredJobType: form.preferredJobType || undefined,
        preferredLocation: form.preferredLocation || undefined,
        expectedStipend: form.expectedStipend ? parseFloat(form.expectedStipend) : undefined,
        preferredIndustry: form.preferredIndustry || undefined,
        isOpenToRemote: form.isOpenToRemote,
        isOpenToRelocation: form.isOpenToRelocation,
        noticePeriodDays: form.noticePeriodDays ? parseInt(form.noticePeriodDays) : undefined,
      }, token);
      setSaved(true); setTimeout(() => setSaved(false), 2500);
    } catch (e: any) { setError(e.message); }
    finally { setSaving(false); }
  };

  if (loading) return <div style={{ color: 'var(--text-secondary)', padding: '20px' }}>Loading…</div>;

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
        <div>
          <label style={labelStyle}>Preferred Job Type</label>
          <select style={{ ...inputStyle, cursor: 'pointer' }} value={form.preferredJobType} onChange={(e) => setForm({ ...form, preferredJobType: e.target.value })}>
            <option value="">— Select —</option>
            <option value="Internship">Internship</option>
            <option value="Full-Time">Full-Time</option>
            <option value="Part-Time">Part-Time</option>
            <option value="Contract">Contract</option>
            <option value="Freelance">Freelance</option>
          </select>
        </div>
        <div>
          <label style={labelStyle}>Preferred Location</label>
          <input style={inputStyle} value={form.preferredLocation} onChange={(e) => setForm({ ...form, preferredLocation: e.target.value })} placeholder="Colombo, Remote…" />
        </div>
        <div>
          <label style={labelStyle}>Expected Stipend (LKR/month)</label>
          <input type="number" style={inputStyle} value={form.expectedStipend} onChange={(e) => setForm({ ...form, expectedStipend: e.target.value })} placeholder="75000" />
        </div>
        <div>
          <label style={labelStyle}>Preferred Industry</label>
          <input style={inputStyle} value={form.preferredIndustry} onChange={(e) => setForm({ ...form, preferredIndustry: e.target.value })} placeholder="FinTech, EdTech, Healthcare…" />
        </div>
        <div>
          <label style={labelStyle}>Notice Period (days)</label>
          <input type="number" style={inputStyle} value={form.noticePeriodDays} onChange={(e) => setForm({ ...form, noticePeriodDays: e.target.value })} placeholder="14" />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', gap: '10px', paddingBottom: '4px' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer' }}>
            <input type="checkbox" checked={form.isOpenToRemote} onChange={(e) => setForm({ ...form, isOpenToRemote: e.target.checked })} />
            <span style={{ fontSize: '14px' }}>Open to Remote Work</span>
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer' }}>
            <input type="checkbox" checked={form.isOpenToRelocation} onChange={(e) => setForm({ ...form, isOpenToRelocation: e.target.checked })} />
            <span style={{ fontSize: '14px' }}>Open to Relocation</span>
          </label>
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <button className="btn-action btn-approve" onClick={handleSave} disabled={saving} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {saving ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
          {saving ? 'Saving…' : 'Save Preferences'}
        </button>
        {saved && <span style={{ color: '#10b981', fontSize: '13px', fontWeight: 600 }}><CheckCircle size={14} style={{ display: 'inline', marginRight: '4px' }} />Saved!</span>}
        {error && <span style={{ color: '#ef4444', fontSize: '13px' }}>{error}</span>}
      </div>
    </div>
  );
};

// ─── Tab: CV & Certificates ───────────────────────────────────────────────────
const CVTab: React.FC<{ candidateId: number; token: string; onChanged: () => void }> = ({
  candidateId, token, onChanged,
}) => {
  const fileRef = useRef<HTMLInputElement>(null);
  const [cv, setCv] = useState<CVDocumentDto | null>(null);
  const [certs, setCerts] = useState<CertificateDto[]>([]);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');
  const [showCertForm, setShowCertForm] = useState(false);
  const blankCert: CreateCertificateDto = { name: '', issuingOrganization: '', issueDate: '' };
  const [certForm, setCertForm] = useState<CreateCertificateDto>(blankCert);
  const [certSaving, setCertSaving] = useState(false);
  const [certError, setCertError] = useState('');

  const loadAll = async () => {
    const [c, cs] = await Promise.all([
      api.getCVDocument(candidateId, token).catch(() => null),
      api.getCertificates(candidateId, token).catch(() => [] as CertificateDto[]),
    ]);
    setCv(c); setCerts(cs);
  };

  useEffect(() => { loadAll(); }, [candidateId]);

  const handleUpload = async (file: File) => {
    if (!['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'].includes(file.type)) {
      setUploadError('Only PDF, DOC, or DOCX files are allowed.'); return;
    }
    if (file.size > 5 * 1024 * 1024) { setUploadError('File must be under 5 MB.'); return; }
    setUploading(true); setUploadError('');
    try {
      const doc = await api.uploadCV(candidateId, file, token);
      setCv(doc); onChanged();
    } catch (e: any) { setUploadError(e.message); }
    finally { setUploading(false); }
  };

  const handleAddCert = async () => {
    setCertSaving(true); setCertError('');
    try {
      await api.addCertificate(candidateId, certForm, token);
      await loadAll(); setShowCertForm(false); setCertForm(blankCert);
    } catch (e: any) { setCertError(e.message); }
    finally { setCertSaving(false); }
  };

  const handleDeleteCert = async (id: number) => {
    if (!window.confirm('Delete this certificate?')) return;
    await api.deleteCertificate(candidateId, id, token).catch(() => {});
    await loadAll();
  };

  return (
    <div>
      {/* CV Upload */}
      <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '12px' }}>CV / Resume *</h4>
      <div
        style={{ border: '2px dashed var(--border-color)', borderRadius: '12px', padding: '28px', textAlign: 'center', background: 'rgba(255,255,255,0.02)', marginBottom: '28px', cursor: 'pointer' }}
        onClick={() => fileRef.current?.click()}
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => { e.preventDefault(); const f = e.dataTransfer.files[0]; if (f) handleUpload(f); }}
      >
        <input ref={fileRef} type="file" accept=".pdf,.doc,.docx" style={{ display: 'none' }} onChange={(e) => { const f = e.target.files?.[0]; if (f) handleUpload(f); }} />
        {uploading ? (
          <><Loader2 size={32} color="#6366f1" className="spin" style={{ marginBottom: '8px' }} /><div style={{ fontWeight: 600, fontSize: '14px' }}>Uploading…</div></>
        ) : cv ? (
          <>
            <FileText size={32} color="#10b981" style={{ marginBottom: '8px' }} />
            <div style={{ fontWeight: 700, fontSize: '15px', color: '#10b981' }}>{cv.fileName}</div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '4px' }}>
              {cv.fileSizeBytes ? `${(cv.fileSizeBytes / 1024).toFixed(1)} KB · ` : ''}Uploaded {fmtDate(cv.uploadedAt)}
            </div>
            <div style={{ color: '#06b6d4', fontSize: '12px', marginTop: '6px' }}>Click or drag to replace</div>
          </>
        ) : (
          <>
            <UploadCloud size={32} color="#6366f1" style={{ marginBottom: '8px' }} />
            <div style={{ fontWeight: 600, fontSize: '14px' }}>Drop your CV here or click to browse</div>
            <div style={{ color: 'var(--text-secondary)', fontSize: '12px', marginTop: '4px' }}>PDF, DOC, DOCX · Max 5 MB</div>
          </>
        )}
      </div>
      {uploadError && <div style={{ color: '#ef4444', fontSize: '13px', marginTop: '-20px', marginBottom: '16px' }}>{uploadError}</div>}

      {/* Certificates */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
        <h4 style={{ fontSize: '13px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Certificates & Courses ({certs.length})</h4>
        {!showCertForm && (
          <button className="btn-action btn-approve" onClick={() => setShowCertForm(true)} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '8px 14px' }}>
            <Plus size={15} /> Add Certificate
          </button>
        )}
      </div>

      {showCertForm && (
        <div className="glass-panel" style={{ padding: '20px', marginBottom: '16px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={labelStyle}>Certificate Name *</label>
              <input style={inputStyle} value={certForm.name} onChange={(e) => setCertForm({ ...certForm, name: e.target.value })} placeholder="AWS Certified Solutions Architect" />
            </div>
            <div>
              <label style={labelStyle}>Issuing Organization *</label>
              <input style={inputStyle} value={certForm.issuingOrganization} onChange={(e) => setCertForm({ ...certForm, issuingOrganization: e.target.value })} placeholder="Amazon Web Services" />
            </div>
            <div>
              <label style={labelStyle}>Issue Date *</label>
              <input type="date" style={inputStyle} value={certForm.issueDate} onChange={(e) => setCertForm({ ...certForm, issueDate: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Expiry Date</label>
              <input type="date" style={inputStyle} value={certForm.expiryDate ?? ''} onChange={(e) => setCertForm({ ...certForm, expiryDate: e.target.value })} />
            </div>
            <div>
              <label style={labelStyle}>Credential ID</label>
              <input style={inputStyle} value={certForm.credentialId ?? ''} onChange={(e) => setCertForm({ ...certForm, credentialId: e.target.value })} placeholder="ABC-12345" />
            </div>
            <div>
              <label style={labelStyle}>Credential URL</label>
              <input style={inputStyle} value={certForm.credentialUrl ?? ''} onChange={(e) => setCertForm({ ...certForm, credentialUrl: e.target.value })} placeholder="https://verify.example.com/..." />
            </div>
          </div>
          {certError && <div style={{ color: '#ef4444', marginTop: '10px', fontSize: '13px' }}>{certError}</div>}
          <div style={{ display: 'flex', gap: '10px', marginTop: '16px' }}>
            <button className="btn-action btn-approve" onClick={handleAddCert} disabled={certSaving} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              {certSaving ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
              {certSaving ? 'Saving…' : 'Save'}
            </button>
            <button onClick={() => setShowCertForm(false)} style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--text-secondary)', border: '1px solid var(--border-color)', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer' }}>
              Cancel
            </button>
          </div>
        </div>
      )}

      {certs.length === 0 && !showCertForm && <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>No certificates added yet.</p>}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
        {certs.map((cert) => (
          <div key={cert.id} className="glass-panel" style={{ padding: '14px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontWeight: 700, fontSize: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Award size={15} color="#f59e0b" />
                {cert.name}
              </div>
              <div style={{ color: '#06b6d4', fontSize: '12px', marginTop: '2px' }}>{cert.issuingOrganization}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>
                Issued {fmtDate(cert.issueDate)}{cert.expiryDate ? ` · Expires ${fmtDate(cert.expiryDate)}` : ''}
              </div>
              {cert.credentialUrl && (
                <a href={cert.credentialUrl} target="_blank" rel="noopener noreferrer" style={{ color: '#818cf8', fontSize: '11px' }}>
                  Verify Credential →
                </a>
              )}
            </div>
            <button onClick={() => handleDeleteCert(cert.id)} style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.3)', padding: '6px 10px', borderRadius: '6px', cursor: 'pointer' }}>
              <Trash2 size={14} />
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── Main Page ────────────────────────────────────────────────────────────────
type Tab = 'profile' | 'skills' | 'education' | 'experience' | 'preferences' | 'cv';

const TABS: { id: Tab; label: string; icon: React.ReactNode }[] = [
  { id: 'profile', label: 'Personal Details', icon: <User size={16} /> },
  { id: 'skills', label: 'Skills', icon: <Code2 size={16} /> },
  { id: 'education', label: 'Education', icon: <GraduationCap size={16} /> },
  { id: 'experience', label: 'Experience', icon: <Briefcase size={16} /> },
  { id: 'preferences', label: 'Preferences', icon: <Settings size={16} /> },
  { id: 'cv', label: 'CV & Certs', icon: <FileText size={16} /> },
];

export const CandidateProfile: React.FC = () => {
  const { user } = useAuth();
  const candidateId = user?.candidateId;
  const token = user?.token ?? '';

  const [activeTab, setActiveTab] = useState<Tab>('profile');
  const [profile, setProfile] = useState<CandidateProfileDto | null>(null);
  const [completeness, setCompleteness] = useState<ProfileCompletenessDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');

  const loadProfile = async () => {
    if (!candidateId) { setLoadError('No candidateId on session. Please log out and log back in.'); setLoading(false); return; }
    try {
      const [p, c] = await Promise.all([
        api.getMyProfile(token),
        api.getProfileCompleteness(candidateId, token),
      ]);
      setProfile(p); setCompleteness(c);
    } catch (e: any) {
      setLoadError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadProfile(); }, [candidateId]);

  const refreshCompleteness = async () => {
    if (!candidateId) return;
    try {
      setCompleteness(await api.getProfileCompleteness(candidateId, token));
    } catch (e) {
      setCompleteness(null);
      setLoadError(e instanceof Error ? e.message : 'Completeness could not be checked.');
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh', flexDirection: 'column', gap: '16px' }}>
        <Loader2 size={40} color="#6366f1" className="spin" />
        <div style={{ color: 'var(--text-secondary)' }}>Loading your profile…</div>
      </div>
    );
  }

  if (loadError || !profile || !candidateId) {
    return (
      <div style={{ padding: '40px', textAlign: 'center', color: '#ef4444' }}>
        <AlertTriangle size={40} style={{ marginBottom: '12px' }} />
        <div style={{ fontWeight: 700, fontSize: '16px' }}>{loadError || 'Profile not found.'}</div>
        <div style={{ color: 'var(--text-secondary)', marginTop: '8px', fontSize: '13px' }}>
          Make sure you are logged in as a Candidate and the backend is running.
        </div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800 }}>My Profile & Skills</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px', fontSize: '14px' }}>
            Manage your candidate profile, skills, education, experience, and CV.
          </p>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontWeight: 700 }}>{profile.fullName}</div>
            <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{profile.email}</div>
          </div>
          <div style={{ width: '44px', height: '44px', borderRadius: '50%', background: 'linear-gradient(135deg, #6366f1, #06b6d4)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: '18px' }}>
            {profile.fullName.charAt(0).toUpperCase()}
          </div>
        </div>
      </div>

      {/* Completeness Widget */}
      {completeness && <CompletenessWidget data={completeness} onRefresh={refreshCompleteness} />}

      {/* Tab Navigation */}
      <div style={{ display: 'flex', gap: '4px', marginBottom: '24px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px', padding: '4px', border: '1px solid var(--border-color)' }}>
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setActiveTab(t.id)}
            style={{
              flex: 1,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '6px',
              padding: '9px 6px',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontSize: '13px',
              fontWeight: 600,
              transition: 'all 0.2s',
              background: activeTab === t.id ? 'rgba(99,102,241,0.25)' : 'transparent',
              color: activeTab === t.id ? '#818cf8' : 'var(--text-secondary)',
            }}
          >
            {t.icon}
            <span style={{ display: 'none' }}>{t.label}</span>
            <span style={{ fontSize: '11px', display: 'block' }}>{t.label}</span>
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="glass-panel" style={{ padding: '28px' }}>
        {activeTab === 'profile' && (
          <ProfileTab
            profile={profile}
            candidateId={candidateId}
            token={token}
            onSaved={(p) => { setProfile(p); refreshCompleteness(); }}
          />
        )}
        {activeTab === 'skills' && (
          <SkillsTab candidateId={candidateId} token={token} onChanged={refreshCompleteness} />
        )}
        {activeTab === 'education' && (
          <EducationTab candidateId={candidateId} token={token} onChanged={refreshCompleteness} />
        )}
        {activeTab === 'experience' && (
          <ExperienceTab candidateId={candidateId} token={token} onChanged={refreshCompleteness} />
        )}
        {activeTab === 'preferences' && (
          <PreferencesTab candidateId={candidateId} token={token} />
        )}
        {activeTab === 'cv' && (
          <CVTab candidateId={candidateId} token={token} onChanged={refreshCompleteness} />
        )}
      </div>

      {/* Spin animation */}
      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }`}</style>
    </div>
  );
};
