'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import Icon, { faEye, faEyeSlash, faEnvelope, faLock, faPhone } from '@/app/components/Icon';
import DigitalClock from '@/app/components/DigitalClock';
import PhoneInput from 'react-phone-input-2';
import 'react-phone-input-2/lib/style.css';

export default function LoginPage() {
  const router = useRouter();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [isPhoneLogin, setIsPhoneLogin] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  // Check for registration success message
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      if (params.get('registered') === 'true') {
        setSuccessMessage('Registration successful! Please log in with your credentials.');
        setTimeout(() => {
          router.replace('/auth/login', { scroll: false });
        }, 100);
      }
    }
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      // Validate identifier is not empty
      if (!identifier.trim()) {
        setError(isPhoneLogin ? 'Phone number is required' : 'Email is required');
        setLoading(false);
        return;
      }

      const { login } = useAuthStore.getState();
      
      // Normalize identifier
      let normalizedIdentifier = identifier.trim();
      
      if (isPhoneLogin) {
        // Phone login: react-phone-input-2 already includes country code
        // The value is in format: "250788123456" (country code + number, no +)
        // Backend expects digits only, which is what we get from the component
        if (!normalizedIdentifier || normalizedIdentifier.length < 9) {
          setError('Please enter a valid phone number');
          setLoading(false);
          return;
        }
        // Remove any non-digits just to be safe
        normalizedIdentifier = normalizedIdentifier.replace(/\D/g, '');
      } else {
        // Email login: keep as is, just trim
        if (!normalizedIdentifier.includes('@')) {
          setError('Please enter a valid email address');
          setLoading(false);
          return;
        }
      }
      
      // Ensure normalized identifier is not empty after processing
      if (!normalizedIdentifier) {
        setError(isPhoneLogin ? 'Invalid phone number format' : 'Email is required');
        setLoading(false);
        return;
      }
      
      const result = await login({ email: normalizedIdentifier, password });

      if ('error' in result) {
        setError(result.error);
        setLoading(false);
        return;
      }

      // Small delay to ensure state is fully updated
      await new Promise(resolve => setTimeout(resolve, 100));

      // Redirect to dashboard
      router.push('/dashboard');
    } catch (err: any) {
      setError(err?.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left Side - Login Form */}
      <div className="w-full lg:w-[40%] flex items-center justify-center p-6 sm:p-8 lg:p-12 bg-white">
        <div className="w-full max-w-sm">
          {/* Logo */}
          <div className="mb-8">
            <div className="w-16 h-16 bg-[var(--primary)] rounded-full flex items-center justify-center mb-4">
              <span className="text-white font-bold text-2xl">G</span>
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Log In to Gemura</h1>
            <p className="text-sm text-gray-600">
              New Here?{' '}
              <Link href="/auth/register" className="text-[var(--primary)] hover:text-[#003d8f] font-medium">
                Create Account
              </Link>
            </p>
          </div>

          {/* Success Message */}
          {successMessage && (
            <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-sm text-sm text-green-600">
              {successMessage}
            </div>
          )}

          {/* Error Message */}
          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-sm text-sm text-red-600">
              {error}
            </div>
          )}

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Toggle between Email and Phone */}
            <div className="flex items-center gap-2 mb-2">
              <button
                type="button"
                onClick={() => {
                  setIsPhoneLogin(false);
                  setIdentifier('');
                  setError('');
                }}
                className={`flex-1 py-2 px-4 text-sm font-medium rounded-sm transition-colors ${
                  !isPhoneLogin
                    ? 'bg-[var(--primary)] text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
                disabled={loading}
              >
                Email
              </button>
              <button
                type="button"
                onClick={() => {
                  setIsPhoneLogin(true);
                  setIdentifier('');
                  setError('');
                }}
                className={`flex-1 py-2 px-4 text-sm font-medium rounded-sm transition-colors ${
                  isPhoneLogin
                    ? 'bg-[var(--primary)] text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
                disabled={loading}
              >
                Phone
              </button>
            </div>

            {/* Email/Phone Field */}
            <div className="relative">
              <label htmlFor="identifier" className="block text-sm font-medium text-gray-700 mb-2">
                {isPhoneLogin ? 'Phone Number' : 'Email Address'}
              </label>
              {isPhoneLogin ? (
                <div className="relative">
                  <PhoneInput
                    country="rw"
                    value={identifier}
                    onChange={(value) => setIdentifier(value)}
                    inputProps={{
                      id: 'identifier',
                      required: true,
                      disabled: loading,
                    }}
                    containerClass="phone-input-container"
                    placeholder="Enter your phone number"
                    preferredCountries={['rw', 'ke', 'ug', 'tz']}
                  />
                </div>
              ) : (
                <div className="relative">
                  <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                    <Icon icon={faEnvelope} size="sm" />
                  </div>
                  <input
                    id="identifier"
                    type="email"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    className="input pl-11"
                    placeholder="Enter your email"
                    required
                    disabled={loading}
                  />
                </div>
              )}
            </div>

            {/* Password Field */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <div className="relative">
                <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 z-10">
                  <Icon icon={faLock} size="sm" />
                </div>
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="input pl-11 pr-12"
                  placeholder="Enter your password"
                  required
                  disabled={loading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  tabIndex={-1}
                >
                  <Icon icon={showPassword ? faEyeSlash : faEye} size="sm" />
                </button>
              </div>
            </div>

            {/* Forgot Password */}
            <div className="flex items-center justify-end">
              <Link
                href="/auth/forgot-password"
                className="text-sm text-[var(--primary)] hover:text-[#003d8f] font-medium"
              >
                Forgot Password?
              </Link>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="btn btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-sm"
            >
              {loading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  <span>Logging in...</span>
                </>
              ) : (
                'Log In'
              )}
            </button>
          </form>

          {/* Footer */}
          <div className="mt-12 text-center">
            <p className="text-xs text-gray-500 mb-2">© 2025 Gemura</p>
            <p className="text-xs text-gray-500">
              Financial Services Platform
            </p>
          </div>
        </div>
      </div>

      {/* Right Side - Cover Image */}
      <div className="hidden lg:flex lg:w-[60%] relative">
        <div 
          className="absolute inset-0 bg-cover bg-center bg-no-repeat"
          style={{
            backgroundImage: 'url("/cover.jpg")',
          }}
        >
          <div className="absolute inset-0 bg-black/40"></div>
        </div>
        <div className="relative z-10 flex items-center justify-center w-full">
          <DigitalClock />
        </div>
      </div>
    </div>
  );
}
