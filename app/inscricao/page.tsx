import type { Metadata } from 'next';
import RegistrationForm from './registration-form';
import './registration.css';
export const metadata: Metadata = {title:'Pré-inscrição | BEZA INOVAÇÕES',description:'Pré-inscrição no Centro de Formação BEZA INOVAÇÕES — inscrição à distância com envio dos documentos e comprovativo de pagamento.'};
export default function RegistrationPage(){return <RegistrationForm/>;}
