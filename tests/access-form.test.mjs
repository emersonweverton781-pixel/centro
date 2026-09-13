import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';

const moduleURL=source=>'data:text/javascript;base64,'+Buffer.from(source).toString('base64');
function compile(source){let js=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022,jsx:ts.JsxEmit.ReactJSX}}).outputText;for(const name of ['react','react/jsx-runtime','@base-ui/react/button','class-variance-authority','lucide-react'])js=js.replaceAll(JSON.stringify(name),JSON.stringify(import.meta.resolve(name))).replaceAll("'"+name+"'",JSON.stringify(import.meta.resolve(name)));return js;}
const buttonSource=await readFile(new URL('../components/ui/button.tsx',import.meta.url),'utf8');
const button=moduleURL(compile(buttonSource).replace(/(['"])@\/lib\/utils\1/g,JSON.stringify(moduleURL('export const cn=(...values)=>values.filter(Boolean).join(" ");'))));
const source=await readFile(new URL('../app/backend.tsx',import.meta.url),'utf8');
const access=source.slice(source.indexOf('export function AccessScreen()'),source.indexOf('export function RemoteAttachment'));
const {AccessScreen}=await import(moduleURL(compile(`import {useState,useEffect} from 'react';import {Eye,EyeOff} from 'lucide-react';import {Button} from ${JSON.stringify(button)};${access}`)));

test('access form submits through the real button primitive; password visibility never submits',()=>{
 const html=renderToStaticMarkup(React.createElement(AccessScreen));
 const buttons=html.match(/<button\b[^>]*>/g)||[];
 assert.equal(buttons.filter(tag=>tag.includes('type="submit"')).length,1,'The shared login/password-save button must submit the form');
 const toggle=buttons.find(tag=>tag.includes('aria-label="Mostrar palavra-passe"'));
 assert.ok(toggle?.includes('type="button"'));
 assert.ok(toggle.includes('aria-pressed="false"'));
 assert.match(html,/<input[^>]*id="beza-password"[^>]*type="password"/);
 assert.match(html,/Usa pelo menos 8 caracteres/);
});
