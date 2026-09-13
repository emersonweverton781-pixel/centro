'use client';
import {useState} from 'react';
import {Button} from '@/components/ui/button';
import {rpc} from '@/lib/supabase';
import {approvedDocument,whatsappURL,type ApprovedDocument} from '@/lib/enrolment-document';
import type {DocumentData} from '@/lib/documents';
import type {Entry} from '@/lib/office';
import DocumentViewer from './document-viewer';
export function RegistrationDocumentButton({entryId}:{entryId:string}){
 const [doc,setDoc]=useState<DocumentData|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 async function open(){setBusy(true);setError('');try{setDoc(approvedDocument(await rpc<ApprovedDocument>('centro_document',{p_entry:entryId})));}catch(e){setError((e as Error).message);}finally{setBusy(false);}}
 return <><Button type="button" className="primary" disabled={busy} onClick={open}>{busy?'A consultar comprovativo…':'Ver / descarregar PDF'}</Button>{error&&<p className="office-error" role="alert">{error} Tente novamente.</p>}{doc&&<DocumentViewer data={doc} close={()=>setDoc(null)}/>}</>;
}
export default function EnrolmentActions({entry,name,phone,course}:{entry:Entry;name:string;phone:string;course:string}){
 const [opened,setOpened]=useState(false);
 const message=entry.status==='Confirmada'?`Olá, ${name}. A BEZA INOVAÇÕES confirmou a sua inscrição no curso ${course}, período ${entry.period}. Matrícula: ${entry.reference}. Contacte a Secretaria para confirmar a data de arranque e obter o comprovativo. Contactos: 947 968 650 / 952 042 462.`:`Olá, ${name}. A BEZA INOVAÇÕES analisou o seu pedido para ${course}. A pré-inscrição foi rejeitada. Motivo: ${entry.reason}. Contacte a Secretaria para esclarecimentos: 947 968 650 / 952 042 462.`;
 const url=whatsappURL(phone,message);
 return <section className="office-detail-section"><h3>Comprovativo e comunicação</h3>{entry.status==='Confirmada'&&<RegistrationDocumentButton entryId={entry.id}/>}<h4>Mensagem para o formando</h4><p style={{whiteSpace:'pre-wrap'}}>{message}</p>{url?<a className="registration-link" href={url} target="_blank" rel="noopener noreferrer" onClick={()=>setOpened(true)}>Abrir mensagem no WhatsApp</a>:<p className="office-error">Corrija o telefone na ficha do aluno, incluindo o indicativo do país.</p>}<p className="academic-muted" role="status">{opened?'Mensagem preparada. Confirme o envio na janela do WhatsApp. O sistema não confirma a entrega.':'Envio manual: a mensagem só será enviada quando confirmar no WhatsApp.'}</p></section>;
}
