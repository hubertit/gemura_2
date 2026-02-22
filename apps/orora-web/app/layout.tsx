import type { Metadata } from "next";
import "./globals.css";
import "./config/fontawesome";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://orora.rw'),
  title: {
    default: "Orora - Cattle Farming Platform",
    template: "%s | Orora",
  },
  description: "Orora's comprehensive platform for cattle farmers - livestock management, milk collection, sales, and farm financial operations",
  keywords: ["orora", "cattle farming", "livestock", "milk collection", "dairy farming", "cattle management"],
  authors: [{ name: "Orora" }],
  creator: "Orora",
  publisher: "Orora",
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
