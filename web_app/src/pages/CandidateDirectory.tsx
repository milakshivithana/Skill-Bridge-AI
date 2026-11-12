import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import type {
  CandidateSummaryDto,
  SkillDto,
} from '../services/api';
import {
  Search,
  MapPin,
  Code2,
  Plus,
  Loader2,
  Users,
  ChevronLeft,
  ChevronRight,
  X,
} from 'lucide-react';

// ─── Skill Tag ────────────────────────────────────────────────────────────────
const SkillTag: React.FC<{ name: string }> = ({ name }) => (
  <span
    style={{
      background: 'rgba(99,102,241,0.15)',
      color: '#818cf8',
      border: '1px solid rgba(99,102,241,0.35)',
      padding: '3px 10px',
      borderRadius: '12px',
      fontSize: '11px',
      fontWeight: 600,
    }}
  >
    {name}
  </span>
);

// ─── Completeness Bar ─────────────────────────────────────────────────────────
const CompletionBar: React.FC<{ pct: number }> = ({ pct }) => {
  const color = pct === 100 ? '#10b981' : pct >= 67 ? '#f59e0b' : '#ef4444';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
      <div
        style={{
          flex: 1,
          height: '6px',
          borderRadius: '3px',
          background: 'rgba(255,255,255,0.08)',
          overflow: 'hidden',
        }}
      >
        <div style={{ height: '100%', width: `${pct}%`, background: color, borderRadius: '3px' }} />
      </div>
      <span style={{ fontSize: '12px', fontWeight: 700, color, minWidth: '36px' }}>{pct}%</span>
    </div>
  );
};

// ─── Candidate Card ───────────────────────────────────────────────────────────
const CandidateCard: React.FC<{ candidate: CandidateSummaryDto }> = ({ candidate }) => (
  <div
    className="glass-panel"
    style={{
      padding: '20px',
      display: 'flex',
      flexDirection: 'column',
      gap: '12px',
      transition: 'transform 0.2s, border-color 0.2s',
      cursor: 'default',
    }}
    onMouseEnter={(e) => {
      (e.currentTarget as HTMLDivElement).style.transform = 'translateY(-2px)';
      (e.currentTarget as HTMLDivElement).style.borderColor = 'rgba(99,102,241,0.5)';
    }}
    onMouseLeave={(e) => {
      (e.currentTarget as HTMLDivElement).style.transform = 'translateY(0)';
      (e.currentTarget as HTMLDivElement).style.borderColor = 'var(--border-color)';
    }}
  >
    {/* Header */}
    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
      <div
        style={{
          width: '42px',
          height: '42px',
          borderRadius: '50%',
          background: 'linear-gradient(135deg, #6366f1, #06b6d4)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontWeight: 800,
          fontSize: '17px',
          flexShrink: 0,
        }}
      >
        {candidate.fullName.charAt(0).toUpperCase()}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontWeight: 700, fontSize: '15px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {candidate.fullName}
        </div>
        <div style={{ color: 'var(--text-secondary)', fontSize: '12px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {candidate.email}
        </div>
      </div>
      <span style={{ fontSize: '11px', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: '3px', flexShrink: 0 }}>
        <MapPin size={11} />
        {candidate.city ?? 'Unknown'}
      </span>
    </div>

    {/* Completeness */}
    <CompletionBar pct={candidate.profileScorePercentage} />

    {/* Skills */}
    {candidate.skills.length > 0 ? (
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
        {candidate.skills.slice(0, 6).map((s) => <SkillTag key={s} name={s} />)}
        {candidate.skills.length > 6 && (
          <span style={{ fontSize: '11px', color: 'var(--text-secondary)', alignSelf: 'center' }}>
            +{candidate.skills.length - 6} more
          </span>
        )}
      </div>
    ) : (
      <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>No skills listed</span>
    )}
  </div>
);

// ─── Skill Taxonomy Manager ───────────────────────────────────────────────────
const TaxonomyManager: React.FC<{ token: string }> = ({ token }) => {
  const [skills, setSkills] = useState<SkillDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const [category, setCategory] = useState('');
  const [adding, setAdding] = useState(false);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true);
    const s = await api.getAllSkills(token).catch(() => [] as SkillDto[]);
    setSkills(s);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const handleAdd = async () => {
    if (!name.trim()) { setError('Skill name is required.'); return; }
    setAdding(true); setError('');
    try {
      await api.createSkill({ name: name.trim(), category: category.trim() || undefined }, token);
      setName(''); setCategory('');
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setAdding(false);
    }
  };

  const groupedByCategory = skills.reduce<Record<string, SkillDto[]>>((acc, s) => {
    const key = s.category || 'General';
    (acc[key] ||= []).push(s);
    return acc;
  }, {});

  return (
    <div>
      <h3 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        <Code2 size={18} color="#06b6d4" /> Skill Taxonomy Management
      </h3>

      {/* Add skill form */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '20px', flexWrap: 'wrap' }}>
        <input
          style={{ flex: '1 1 180px', padding: '9px 14px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', fontSize: '14px' }}
          placeholder="Skill name (e.g. React, Python)"
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
        />
        <input
          style={{ flex: '1 1 150px', padding: '9px 14px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', fontSize: '14px' }}
          placeholder="Category (e.g. Frontend)"
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
        />
        <button
          className="btn-action btn-approve"
          onClick={handleAdd}
          disabled={adding}
          style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '9px 18px' }}
        >
          {adding ? <Loader2 size={15} className="spin" /> : <Plus size={15} />}
          Add Skill
        </button>
      </div>
      {error && <div style={{ color: '#ef4444', fontSize: '13px', marginBottom: '12px' }}>{error}</div>}

      {/* Skill list grouped by category */}
      {loading ? (
        <div style={{ color: 'var(--text-secondary)' }}>Loading taxonomy…</div>
      ) : skills.length === 0 ? (
        <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>No skills in taxonomy yet.</p>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {Object.entries(groupedByCategory).map(([cat, list]) => (
            <div key={cat}>
              <div style={{ fontSize: '11px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.07em', marginBottom: '8px' }}>{cat}</div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                {list.map((s) => (
                  <span
                    key={s.id}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                      background: 'rgba(6,182,212,0.1)',
                      color: '#22d3ee',
                      border: '1px solid rgba(6,182,212,0.3)',
                      padding: '5px 12px',
                      borderRadius: '20px',
                      fontSize: '12px',
                      fontWeight: 600,
                    }}
                  >
                    {s.name}
                  </span>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

// ─── Main Page ────────────────────────────────────────────────────────────────
export const CandidateDirectory: React.FC = () => {
  const { user } = useAuth();
  const token = user?.token ?? '';

  const [candidates, setCandidates] = useState<CandidateSummaryDto[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [page, setPage] = useState(1);
  const PAGE_SIZE = 12;

  const [query, setQuery] = useState('');
  const [cityFilter, setCityFilter] = useState('');
  const [skillFilter, setSkillFilter] = useState('');
  const [activeFilters, setActiveFilters] = useState<{ query?: string; city?: string; skill?: string }>({});

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showTaxonomy, setShowTaxonomy] = useState(false);

  const fetchCandidates = useCallback(async (filters: typeof activeFilters, pg: number) => {
    setLoading(true); setError('');
    try {
      const result = await api.searchCandidates(token, { ...filters, page: pg, pageSize: PAGE_SIZE });
      setCandidates(result.items);
      setTotalCount(result.totalCount);
      setTotalPages(result.totalPages);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => { fetchCandidates(activeFilters, page); }, [activeFilters, page, fetchCandidates]);

  const handleSearch = () => {
    const filters = {
      query: query.trim() || undefined,
      city: cityFilter.trim() || undefined,
      skill: skillFilter.trim() || undefined,
    };
    setActiveFilters(filters);
    setPage(1);
  };

  const handleClearFilters = () => {
    setQuery(''); setCityFilter(''); setSkillFilter('');
    setActiveFilters({}); setPage(1);
  };

  const hasActiveFilters = Object.values(activeFilters).some(Boolean);

  return (
    <div>
      {/* Header */}
      <div className="header-bar">
        <div>
          <h1 style={{ fontSize: '26px', fontWeight: 800 }}>Candidate Directory</h1>
          <p style={{ color: 'var(--text-secondary)', marginTop: '4px', fontSize: '14px' }}>
            Search, filter and review all registered candidates.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={() => setShowTaxonomy(!showTaxonomy)}
            style={{
              display: 'flex', alignItems: 'center', gap: '8px',
              background: showTaxonomy ? 'rgba(6,182,212,0.2)' : 'rgba(6,182,212,0.08)',
              color: '#22d3ee',
              border: '1px solid rgba(6,182,212,0.35)',
              padding: '9px 18px',
              borderRadius: '8px',
              cursor: 'pointer',
              fontWeight: 600,
              fontSize: '13px',
            }}
          >
            <Code2 size={16} />
            {showTaxonomy ? 'Hide Taxonomy' : 'Skill Taxonomy'}
          </button>
        </div>
      </div>

      {/* Taxonomy Manager Panel */}
      {showTaxonomy && (
        <div className="glass-panel" style={{ padding: '24px', marginBottom: '24px' }}>
          <TaxonomyManager token={token} />
        </div>
      )}

      {/* Search & Filter Bar */}
      <div className="glass-panel" style={{ padding: '20px', marginBottom: '24px' }}>
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div style={{ flex: '2 1 220px' }}>
            <label style={{ display: 'block', fontSize: '11px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '5px' }}>
              Search by Name / Email
            </label>
            <div style={{ position: 'relative' }}>
              <Search size={15} color="var(--text-secondary)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                style={{ width: '100%', padding: '9px 14px 9px 36px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', fontSize: '14px', boxSizing: 'border-box' }}
                placeholder="Rashid Ahamed…"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              />
            </div>
          </div>

          <div style={{ flex: '1 1 160px' }}>
            <label style={{ display: 'block', fontSize: '11px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '5px' }}>
              <MapPin size={11} style={{ display: 'inline' }} /> City
            </label>
            <input
              style={{ width: '100%', padding: '9px 14px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', fontSize: '14px', boxSizing: 'border-box' }}
              placeholder="Colombo…"
              value={cityFilter}
              onChange={(e) => setCityFilter(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            />
          </div>

          <div style={{ flex: '1 1 160px' }}>
            <label style={{ display: 'block', fontSize: '11px', color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '5px' }}>
              <Code2 size={11} style={{ display: 'inline' }} /> Skill
            </label>
            <input
              style={{ width: '100%', padding: '9px 14px', borderRadius: '8px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--border-color)', color: '#fff', fontSize: '14px', boxSizing: 'border-box' }}
              placeholder="React, Python…"
              value={skillFilter}
              onChange={(e) => setSkillFilter(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            />
          </div>

          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              className="btn-action btn-approve"
              onClick={handleSearch}
              disabled={loading}
              style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 20px', whiteSpace: 'nowrap' }}
            >
              {loading ? <Loader2 size={15} className="spin" /> : <Search size={15} />}
              Search
            </button>
            {hasActiveFilters && (
              <button
                onClick={handleClearFilters}
                style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '10px 14px', borderRadius: '8px', background: 'rgba(239,68,68,0.1)', color: '#ef4444', border: '1px solid rgba(239,68,68,0.3)', cursor: 'pointer', fontWeight: 600, fontSize: '13px', whiteSpace: 'nowrap' }}
              >
                <X size={14} /> Clear
              </button>
            )}
          </div>
        </div>

        {/* Active filter pills */}
        {hasActiveFilters && (
          <div style={{ display: 'flex', gap: '8px', marginTop: '12px', flexWrap: 'wrap' }}>
            {activeFilters.query && (
              <span style={{ background: 'rgba(99,102,241,0.15)', color: '#818cf8', border: '1px solid rgba(99,102,241,0.35)', padding: '3px 10px', borderRadius: '12px', fontSize: '11px', fontWeight: 600 }}>
                Name: {activeFilters.query}
              </span>
            )}
            {activeFilters.city && (
              <span style={{ background: 'rgba(6,182,212,0.15)', color: '#22d3ee', border: '1px solid rgba(6,182,212,0.35)', padding: '3px 10px', borderRadius: '12px', fontSize: '11px', fontWeight: 600 }}>
                City: {activeFilters.city}
              </span>
            )}
            {activeFilters.skill && (
              <span style={{ background: 'rgba(245,158,11,0.15)', color: '#fbbf24', border: '1px solid rgba(245,158,11,0.35)', padding: '3px 10px', borderRadius: '12px', fontSize: '11px', fontWeight: 600 }}>
                Skill: {activeFilters.skill}
              </span>
            )}
          </div>
        )}
      </div>

      {/* Results header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-secondary)', fontSize: '13px' }}>
          <Users size={15} />
          {loading ? 'Loading…' : `${totalCount} candidate${totalCount !== 1 ? 's' : ''} found`}
        </div>
        {totalPages > 1 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px' }}>
            <span style={{ color: 'var(--text-secondary)' }}>Page {page} of {totalPages}</span>
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1 || loading}
              style={{ background: 'rgba(255,255,255,0.05)', color: page === 1 ? 'var(--text-secondary)' : '#fff', border: '1px solid var(--border-color)', padding: '5px 10px', borderRadius: '6px', cursor: page === 1 ? 'not-allowed' : 'pointer' }}
            >
              <ChevronLeft size={15} />
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages || loading}
              style={{ background: 'rgba(255,255,255,0.05)', color: page === totalPages ? 'var(--text-secondary)' : '#fff', border: '1px solid var(--border-color)', padding: '5px 10px', borderRadius: '6px', cursor: page === totalPages ? 'not-allowed' : 'pointer' }}
            >
              <ChevronRight size={15} />
            </button>
          </div>
        )}
      </div>

      {/* Error */}
      {error && (
        <div style={{ color: '#ef4444', background: 'rgba(239,68,68,0.1)', padding: '12px 16px', borderRadius: '8px', marginBottom: '16px', fontSize: '13px' }}>
          {error}
        </div>
      )}

      {/* Candidate Grid */}
      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '200px', gap: '12px', color: 'var(--text-secondary)' }}>
          <Loader2 size={32} color="#6366f1" className="spin" /> Loading candidates…
        </div>
      ) : candidates.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '60px', color: 'var(--text-secondary)' }}>
          <Users size={40} style={{ marginBottom: '12px', opacity: 0.4 }} />
          <div style={{ fontWeight: 700, fontSize: '15px' }}>No candidates found</div>
          <div style={{ fontSize: '13px', marginTop: '6px' }}>Try adjusting your search filters.</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '16px' }}>
          {candidates.map((c) => <CandidateCard key={c.id} candidate={c} />)}
        </div>
      )}

      {/* Bottom Pagination */}
      {totalPages > 1 && !loading && (
        <div style={{ display: 'flex', justifyContent: 'center', gap: '8px', marginTop: '28px' }}>
          {Array.from({ length: totalPages }, (_, i) => i + 1).map((pg) => (
            <button
              key={pg}
              onClick={() => setPage(pg)}
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '8px',
                border: '1px solid var(--border-color)',
                cursor: 'pointer',
                fontWeight: 700,
                fontSize: '13px',
                background: pg === page ? 'rgba(99,102,241,0.3)' : 'rgba(255,255,255,0.04)',
                color: pg === page ? '#818cf8' : 'var(--text-secondary)',
              }}
            >
              {pg}
            </button>
          ))}
        </div>
      )}

      <style>{`.spin { animation: spin 1s linear infinite; } @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }`}</style>
    </div>
  );
};
