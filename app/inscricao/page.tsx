import type { Metadata } from 'next';
import RegistrationForm from './registration-form';
import './registration.css';
export const metadata: Metadata = {title:'Pré-inscrição | BEZA INOVAÇÕES',description:'Pré-inscrição no Centro de Formação BEZA INOVAÇÕES — demonstração do formulário em quatro passos.'};
export default function RegistrationPage(){return <RegistrationForm/>;}
