import type { Metadata } from 'next';
import './globals.css';
import './beza.css';
export const metadata: Metadata={title:'BEZA INOVAÇÕES | Centro de Formação',description:'Etapa 2 — Pré-inscrição e demonstração da plataforma de gestão do Centro de Formação BEZA INOVAÇÕES.'};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="pt-AO"><body>{children}</body></html>}

