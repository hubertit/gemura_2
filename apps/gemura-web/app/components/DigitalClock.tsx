'use client';

import { useState, useEffect } from 'react';

export default function DigitalClock() {
  const [time, setTime] = useState<Date | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    // Set mounted to true and initialize time only on client
    setMounted(true);
    setTime(new Date());

    const timer = setInterval(() => {
      setTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  const formatTime = (date: Date) => {
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    return { hours, minutes, seconds };
  };

  const formatDate = (date: Date) => {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    const dayName = days[date.getDay()];
    const monthName = months[date.getMonth()];
    const day = date.getDate();
    const year = date.getFullYear();
    
    return `${dayName}, ${monthName} ${day}, ${year}`;
  };

  // Don't render time until mounted to avoid hydration mismatch
  if (!mounted || !time) {
    return (
      <div className="flex flex-col items-center justify-center">
        {/* Digital Clock Placeholder */}
        <div className="bg-black/60 backdrop-blur-sm rounded-lg p-6 mb-4 border border-white/20">
          <div className="flex items-center gap-2">
            <div className="text-6xl font-bold tabular-nums" style={{ color: '#ffffff' }}>
              00
            </div>
            <div className="text-6xl font-bold tabular-nums" style={{ color: 'rgba(255, 255, 255, 0.7)' }}>:</div>
            <div className="text-6xl font-bold tabular-nums" style={{ color: '#ffffff' }}>
              00
            </div>
            <div className="text-6xl font-bold tabular-nums" style={{ color: 'rgba(255, 255, 255, 0.7)' }}>:</div>
            <div className="text-4xl font-bold tabular-nums" style={{ color: 'rgba(255, 255, 255, 0.9)' }}>
              00
            </div>
          </div>
        </div>
        
        {/* Date Placeholder */}
        <div className="bg-black/60 backdrop-blur-sm rounded-lg px-6 py-3 border border-white/20">
          <p className="text-xl font-medium text-center" style={{ color: '#ffffff' }}>
            Loading...
          </p>
        </div>
      </div>
    );
  }

  const { hours, minutes, seconds } = formatTime(time);
  const dateString = formatDate(time);

  return (
    <div className="flex flex-col items-center justify-center">
      {/* Digital Clock */}
      <div className="bg-black/60 backdrop-blur-sm rounded-lg p-6 mb-4 border border-white/20">
        <div className="flex items-center gap-2">
          <div className="text-6xl font-bold tabular-nums" style={{ color: '#ffffff' }} suppressHydrationWarning>
            {hours}
          </div>
          <div className="text-6xl font-bold tabular-nums" style={{ color: 'rgba(255, 255, 255, 0.7)' }}>:</div>
          <div className="text-6xl font-bold tabular-nums" style={{ color: '#ffffff' }} suppressHydrationWarning>
            {minutes}
          </div>
          <div className="text-6xl font-bold tabular-nums" style={{ color: 'rgba(255, 255, 255, 0.7)' }}>:</div>
          <div className="text-4xl font-bold tabular-nums" style={{ color: 'rgba(255, 255, 255, 0.9)' }} suppressHydrationWarning>
            {seconds}
          </div>
        </div>
      </div>
      
      {/* Date */}
      <div className="bg-black/60 backdrop-blur-sm rounded-lg px-6 py-3 border border-white/20">
        <p className="text-xl font-medium text-center" style={{ color: '#ffffff' }} suppressHydrationWarning>
          {dateString}
        </p>
      </div>
    </div>
  );
}
