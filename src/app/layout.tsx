import './globals.css'
import { ReactNode } from 'react'
import type { Metadata } from 'next'

export const metadata: Metadata = {
    title: 'V Farm',
    description: 'Collaborate and build anything with AI-powered tools. From code to design, everything you need in one powerful workspace.',
    keywords: ['AI workspace', 'collaboration', 'development tools', 'full stack', 'productivity'],
    authors: [{ name: 'AppFolio Team' }],
    openGraph: {
        title: 'Vfarm',
        description: 'Collaborate and build anything with AI-powered tools.',
        type: 'website',
    },
}

export default function RootLayout({ children }: { children: ReactNode }) {
    return (
        <html lang='en'>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <link rel="preconnect" href="https://fonts.googleapis.com" />
                <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
                <link href="https://fonts.googleapis.com/css2?family=Londrina+Solid:wght@100;300;400;900&family=Montserrat:ital,wght@0,100..900;1,100..900&family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&family=Rowdies:wght@300;400;700&family=Rubik+Vinyl&family=Sour+Gummy:ital,wght@0,100..900;1,100..900&family=Space+Grotesk:wght@300..700&family=Unbounded:wght@200..900&display=swap" rel="stylesheet" />
                <link href='https://cdn.boxicons.com/3.0.8/fonts/basic/boxicons.min.css' rel='stylesheet' />
                <link href='https://cdn.boxicons.com/3.0.8/fonts/filled/boxicons-filled.min.css' rel='stylesheet' />
                <link href='https://cdn.boxicons.com/3.0.8/fonts/brands/boxicons-brands.min.css' rel='stylesheet' />
            </head>
            <body>
                {children}
            </body>
        </html>
    );
}