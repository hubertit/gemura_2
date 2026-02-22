import type { Metadata } from "next";
import "./globals.css";
import "./config/fontawesome";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://gemura.com'),
  title: {
    default: "Gemura - Financial Services Platform",
    template: "%s | Gemura",
  },
  description: "Gemura's comprehensive platform for milk collection, sales, and financial operations management",
  keywords: ["gemura", "financial services", "milk collection", "sales management", "accounting"],
  authors: [{ name: "Gemura" }],
  creator: "Gemura",
  publisher: "Gemura",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/logo.png" type="image/png" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@400;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="antialiased" suppressHydrationWarning>
        {children}
      </body>
    </html>
  );
}
