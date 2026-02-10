'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import Icon, {
  faBars,
  faSearch,
  faBell,
  faUser,
  faCog,
  faRightFromBracket,
  faChevronDown,
  faSpinner,
} from './Icon';

interface HeaderProps {
  sidebarOpen: boolean;
  sidebarCollapsed: boolean;
  onMenuToggle: () => void;
  onSidebarToggle?: () => void;
}

export default function Header({
  sidebarOpen,
  sidebarCollapsed,
  onMenuToggle,
  onSidebarToggle,
}: HeaderProps) {
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchLoading, setSearchLoading] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [userName, setUserName] = useState('User');
  const [userRole, setUserRole] = useState('User');

  const userMenuRef = useRef<HTMLDivElement>(null);
  const notificationsRef = useRef<HTMLDivElement>(null);
  const searchRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (user) {
      setUserName(`${user.firstName} ${user.lastName}`);
      setUserRole(user.role || 'User');
    }
  }, [user]);

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setUserMenuOpen(false);
      }
      if (notificationsRef.current && !notificationsRef.current.contains(event.target as Node)) {
        setNotificationsOpen(false);
      }
      if (searchRef.current && !searchRef.current.contains(event.target as Node)) {
        setSearchOpen(false);
      }
    };

    if (userMenuOpen || notificationsOpen || searchOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [userMenuOpen, notificationsOpen, searchOpen]);

  const handleLogout = () => {
    logout();
    router.push('/auth/login');
  };

  // Mock notifications
  const notifications: any[] = [];
  const unreadCount = 0;

  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div className="flex items-center h-20 px-4 md:px-6 lg:px-8 gap-4">
        {/* Sidebar Toggle */}
        <button
          onClick={onMenuToggle}
          className="flex items-center justify-center p-2.5 bg-gray-50 border border-gray-200 text-gray-900 cursor-pointer rounded transition-all mr-3 flex-shrink-0 hover:bg-gray-100 hover:border-gray-300 hover:text-[var(--primary)] active:bg-gray-200 active:scale-95 lg:hidden"
          aria-label="Toggle sidebar"
        >
          <Icon icon={faBars} size="sm" />
        </button>

        {/* Search Input */}
        <div className="flex-1 relative hidden sm:block max-w-[240px] md:max-w-[280px] lg:max-w-[360px]" ref={searchRef}>
          <div className="relative w-full">
            <div className={`absolute left-0 top-0 bottom-0 w-12 flex items-center justify-center pointer-events-none text-gray-400 z-10 transition-colors ${searchLoading ? 'animate-spin text-[var(--primary)]' : ''}`}>
              <Icon icon={searchLoading ? faSpinner : faSearch} size="sm" />
            </div>
            <input
              type="text"
              placeholder="Search sales, collections, suppliers..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onFocus={() => {
                if (searchTerm.trim()) {
                  setSearchOpen(true);
                }
              }}
              className="w-full pl-12 pr-4 py-2.5 bg-gray-50 border border-gray-200 rounded-sm text-gray-900 placeholder-gray-500 focus:outline-none focus:bg-white focus:border-[var(--primary)] focus:ring-1 focus:ring-[var(--primary)] text-sm"
            />
          </div>
        </div>

        {/* Spacer */}
        <div className="flex-1"></div>

        {/* Right Actions */}
        <div className="flex items-center gap-3 flex-shrink-0">
          {/* Notifications */}
          <div className="relative" ref={notificationsRef}>
            <button
              onClick={() => {
                setNotificationsOpen(!notificationsOpen);
                setUserMenuOpen(false);
              }}
              className="relative flex items-center justify-center w-10 h-10 p-0 bg-transparent border-none text-gray-700 cursor-pointer rounded-sm transition-all hover:bg-gray-100 active:scale-95"
              aria-label="Notifications"
            >
              <Icon icon={faBell} size="sm" />
              {unreadCount > 0 && (
                <>
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-2 border-white pointer-events-none z-10"></span>
                  <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 bg-red-500 text-white rounded-full text-[10px] font-semibold flex items-center justify-center border-2 border-white pointer-events-none z-10">
                    {unreadCount > 9 ? '9+' : unreadCount}
                  </span>
                </>
              )}
            </button>

            {/* Notifications Dropdown */}
            {notificationsOpen && (
              <div className="absolute right-0 top-full mt-2 w-80 bg-white border border-gray-200 rounded z-[1000] max-h-96 overflow-y-auto">
                <div className="flex items-center justify-between p-4 border-b border-gray-200">
                  <h3 className="text-sm font-semibold text-gray-900 m-0">Notifications</h3>
                  <Link
                    href="/dashboard"
                    onClick={() => setNotificationsOpen(false)}
                    className="text-sm text-[var(--primary)] hover:text-[#003d8f] no-underline"
                  >
                    View All
                  </Link>
                </div>
                <div className="py-2 max-h-[300px] overflow-y-auto">
                  {notifications.length === 0 ? (
                    <div className="p-8 text-center">
                      <p className="text-sm text-gray-500 m-0">No notifications</p>
                    </div>
                  ) : (
                    notifications.slice(0, 5).map((notification) => (
                      <button
                        key={notification.id}
                        type="button"
                        className={`w-full flex items-start gap-3 px-4 py-3 text-left cursor-pointer transition-colors ${
                          !notification.read ? 'bg-[var(--primary)]/5 hover:bg-[var(--primary)]/10' : 'hover:bg-gray-50'
                        }`}
                      >
                        <div className={`flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center`}>
                          <Icon icon={faBell} className="text-gray-600" size="sm" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className={`text-sm ${!notification.read ? 'font-semibold text-gray-900' : 'text-gray-700'} m-0 mb-1`}>
                            {notification.title}
                          </p>
                          <p className="text-xs text-gray-500 m-0">{notification.time}</p>
                        </div>
                        {!notification.read && (
                          <div className="w-1 h-1 bg-[var(--primary)] rounded-full flex-shrink-0 mt-2"></div>
                        )}
                      </button>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>

          {/* User Menu */}
          <div className="relative flex items-center gap-3" ref={userMenuRef}>
            <div className="hidden sm:block text-right">
              <p className="text-sm font-semibold text-gray-900 m-0 leading-tight">{userName}</p>
              <p className="text-xs text-gray-500 m-0 leading-tight capitalize">{userRole}</p>
            </div>
            <button
              onClick={() => {
                setUserMenuOpen(!userMenuOpen);
                setNotificationsOpen(false);
              }}
              className="flex items-center gap-2 p-1 bg-transparent border-none cursor-pointer rounded-sm transition-all hover:bg-gray-100"
              aria-label="User menu"
            >
              <div className="w-9 h-9 bg-[var(--primary)]/10 rounded-full flex items-center justify-center text-[var(--primary)] flex-shrink-0">
                <Icon icon={faUser} size="sm" />
              </div>
              <Icon
                icon={faChevronDown}
                className={`text-gray-600 transition-transform flex-shrink-0 ${userMenuOpen ? 'rotate-180' : ''}`}
                size="sm"
              />
            </button>

            {/* User Dropdown */}
            {userMenuOpen && (
              <div className="absolute right-0 top-full mt-2 w-48 bg-white border border-gray-200 rounded z-[1000]">
                <div className="py-1">
                  {user && (
                    <>
                      <div className="px-4 py-3 border-b border-gray-200">
                        <p className="text-sm font-semibold text-gray-900 m-0 mb-1">{userName}</p>
                        <p className="text-xs text-gray-500 m-0">{user.email || 'No email'}</p>
                      </div>
                      <div className="h-px bg-gray-200 my-1"></div>
                    </>
                  )}
                  <Link
                    href="/settings"
                    onClick={() => setUserMenuOpen(false)}
                    className="flex items-center gap-3 w-full px-4 py-3 bg-transparent border-none text-left text-sm text-gray-700 cursor-pointer no-underline transition-colors hover:bg-gray-50"
                  >
                    <Icon icon={faUser} className="text-gray-500" size="sm" />
                    <span>Profile &amp; Settings</span>
                  </Link>
                  <div className="h-px bg-gray-200 my-1"></div>
                  <button
                    onClick={handleLogout}
                    className="flex items-center gap-3 w-full px-4 py-3 bg-transparent border-none text-left text-sm text-red-600 cursor-pointer transition-colors hover:bg-red-50 hover:text-red-600"
                  >
                    <Icon icon={faRightFromBracket} className="text-gray-500" size="sm" />
                    <span>Logout</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
