import React, { createContext, useContext, useState } from 'react';

export interface UserSession {
  userId: number;
  fullName: string;
  email: string;
  role: 'Candidate' | 'Recruiter' | 'Interviewer' | 'Administrator';
  candidateId?: number;
  interviewerId?: number;
  token: string;
}

interface AuthContextType {
  user: UserSession | null;
  loginUser: (session: UserSession) => void;
  logoutUser: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserSession | null>(() => {
    const saved = localStorage.getItem('skillbridge_user');
    if (saved) {
      try { 
        return JSON.parse(saved); 
      } catch (e) { 
        return null; 
      }
    }
    return null; // Require explicit login
  });

  const loginUser = (session: UserSession) => {
    setUser(session);
    localStorage.setItem('skillbridge_user', JSON.stringify(session));
  };

  const logoutUser = () => {
    setUser(null);
    localStorage.removeItem('skillbridge_user');
  };

  return (
    <AuthContext.Provider value={{ user, loginUser, logoutUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
