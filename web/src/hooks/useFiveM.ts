import { useEffect, useCallback, useState } from 'react';
import { 
  onNuiEvent, 
  closeNui, 
  sendRelationshipRequest,
  acceptRequest as apiAcceptRequest,
  rejectRequest as apiRejectRequest,
  breakup as apiBreakup,
  getRelationshipStatus,
  isInFiveM,
  IncomingRequest,
  RelationshipData,
  SendRequestData
} from '@/utils/fivem';

/**
 * Hook principal para integração com FiveM
 * 
 * Gerencia todos os eventos e callbacks do sistema de relacionamento
 * 
 * @example
 * const { 
 *   isOpen, 
 *   relationshipData, 
 *   pendingRequest,
 *   sendRequest,
 *   acceptRequest,
 *   rejectRequest,
 *   breakup,
 *   close 
 * } = useFiveM();
 */
export function useFiveM() {
  const [isOpen, setIsOpen] = useState(!isInFiveM()); // Aberto por padrão em dev
  const [relationshipData, setRelationshipData] = useState<RelationshipData | null>(null);
  const [pendingRequest, setPendingRequest] = useState<IncomingRequest | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Escuta eventos do Lua
  useEffect(() => {
    // Evento para abrir a UI
    const cleanupOpen = onNuiEvent('openUI', (data: RelationshipData) => {
      setRelationshipData(data);
      setIsOpen(true);
    });

    // Evento para fechar a UI
    const cleanupClose = onNuiEvent('closeUI', () => {
      setIsOpen(false);
      setPendingRequest(null);
    });

    // Evento para receber pedido de relacionamento
    const cleanupRequest = onNuiEvent<IncomingRequest>('receiveRequest', (data) => {
      setPendingRequest(data);
    });

    // Evento para atualizar status do relacionamento
    const cleanupUpdate = onNuiEvent<RelationshipData>('updateStatus', (data) => {
      setRelationshipData(data);
      setPendingRequest(null);
    });

    // Evento para notificações
    const cleanupNotify = onNuiEvent<{ message: string; type: 'success' | 'error' }>('notify', (data) => {
      // Você pode integrar com toast aqui
      console.log(`[${data.type}] ${data.message}`);
    });

    // Listener para tecla ESC fechar a UI
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        close();
      }
    };
    window.addEventListener('keydown', handleKeyDown);

    return () => {
      cleanupOpen();
      cleanupClose();
      cleanupRequest();
      cleanupUpdate();
      cleanupNotify();
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen]);

  // Carrega status inicial quando abre
  useEffect(() => {
    if (isOpen && !relationshipData && isInFiveM()) {
      getRelationshipStatus().then(setRelationshipData);
    }
  }, [isOpen, relationshipData]);

  const sendRequest = useCallback(async (data: SendRequestData) => {
    setIsLoading(true);
    try {
      const response = await sendRelationshipRequest(data);
      return response;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const acceptRequest = useCallback(async () => {
    if (!pendingRequest) return;
    setIsLoading(true);
    try {
      await apiAcceptRequest(pendingRequest.fromId);
      setPendingRequest(null);
    } finally {
      setIsLoading(false);
    }
  }, [pendingRequest]);

  const rejectRequest = useCallback(async () => {
    if (!pendingRequest) return;
    setIsLoading(true);
    try {
      await apiRejectRequest(pendingRequest.fromId);
      setPendingRequest(null);
    } finally {
      setIsLoading(false);
    }
  }, [pendingRequest]);

  const breakup = useCallback(async () => {
    setIsLoading(true);
    try {
      await apiBreakup();
      setRelationshipData({ status: 'single' });
    } finally {
      setIsLoading(false);
    }
  }, []);

  const close = useCallback(() => {
    closeNui();
    setIsOpen(false);
    setPendingRequest(null);
  }, []);

  return {
    isOpen,
    isLoading,
    relationshipData,
    pendingRequest,
    sendRequest,
    acceptRequest,
    rejectRequest,
    breakup,
    close,
  };
}
