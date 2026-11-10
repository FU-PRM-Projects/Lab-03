import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '../index.css';
import FinalDeck from './FinalDeck.tsx';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <FinalDeck />
  </StrictMode>,
);
