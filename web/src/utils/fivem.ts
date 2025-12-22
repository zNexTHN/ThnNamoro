/**
 * FiveM NUI Utilities
 * 
 * Este arquivo contém todas as funções necessárias para comunicação
 * entre a NUI (React) e o cliente Lua do FiveM.
 */

// Detecta se estamos rodando dentro do FiveM
export const isInFiveM = (): boolean => {
  return typeof window !== 'undefined' && 
         'GetParentResourceName' in window;
};

// Obtém o nome do resource (usado para callbacks)
export const getResourceName = (): string => {
  if (isInFiveM()) {
    return (window as any).GetParentResourceName();
  }
  return 'relationship-system'; // fallback para desenvolvimento
};

/**
 * Envia um callback NUI para o cliente Lua
 * 
 * @param eventName - Nome do evento
 * @param data - Dados a serem enviados
 * @returns Promise com a resposta do servidor
 * 
 * @example
 * // No React:
 * await nuiCallback('sendRequest', { targetId: '123', type: 'dating' });
 * 
 * // No Lua (client):
 * RegisterNUICallback('sendRequest', function(data, cb)
 *     local targetId = data.targetId
 *     local requestType = data.type
 *     -- Processa o pedido...
 *     cb({ success = true })
 * end)
 */
export async function nuiCallback<T = any>(eventName: string, data: any = {}): Promise<T> {
  if (!isInFiveM()) {
    console.log(`[DEV] NUI Callback: ${eventName}`, data);
    return { success: true } as T;
  }

  try {
    const response = await fetch(`https://${getResourceName()}/${eventName}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    return await response.json();
  } catch (error) {
    console.error(`[NUI] Erro no callback ${eventName}:`, error);
    throw error;
  }
}

/**
 * Registra um listener para eventos enviados do Lua para a NUI
 * 
 * @param eventName - Nome do evento a escutar
 * @param callback - Função a ser executada quando o evento for recebido
 * @returns Função para remover o listener
 * 
 * @example
 * // No React:
 * useEffect(() => {
 *   const cleanup = onNuiEvent('receiveRequest', (data) => {
 *     setRequest(data);
 *   });
 *   return cleanup;
 * }, []);
 * 
 * // No Lua (client):
 * SendNUIMessage({
 *     type = 'receiveRequest',
 *     data = {
 *         fromId = '123',
 *         fromName = 'João',
 *         requestType = 'dating'
 *     }
 * })
 */
export function onNuiEvent<T = any>(
  eventName: string, 
  callback: (data: T) => void
): () => void {
  const handler = (event: MessageEvent) => {
    const { type, data } = event.data;
    if (type === eventName) {
      callback(data);
    }
  };

  window.addEventListener('message', handler);
  
  return () => {
    window.removeEventListener('message', handler);
  };
}

/**
 * Fecha a NUI e envia foco de volta para o jogo
 * 
 * @example
 * // No React:
 * <button onClick={closeNui}>Fechar</button>
 * 
 * // No Lua, você deve ter:
 * RegisterNUICallback('closeUI', function(_, cb)
 *     SetNuiFocus(false, false)
 *     cb('ok')
 * end)
 */
export function closeNui(): void {
  nuiCallback('closeUI');
}

// ============================================
// CALLBACKS ESPECÍFICOS DO SISTEMA
// ============================================

export interface SendRequestData {
  targetId: string;
  type: 'dating' | 'engagement' | 'marriage';
}

export interface RequestResponse {
  success: boolean;
  message?: string;
}

export interface RelationshipData {
  status: 'single' | 'dating' | 'engaged' | 'married';
  partner?: {
    id: string;
    name: string;
    avatar?: string;
    startDate: string; // ISO date string
  };
}

export interface IncomingRequest {
  fromId: string;
  fromName: string;
  fromAvatar?: string;
  type: 'dating' | 'engagement' | 'marriage';
}

/**
 * Envia um pedido de relacionamento para outro jogador
 */
export const sendRelationshipRequest = (data: SendRequestData): Promise<RequestResponse> => {
  return nuiCallback('sendRequest', data);
};

/**
 * Aceita um pedido de relacionamento recebido
 */
export const acceptRequest = (fromId: string): Promise<RequestResponse> => {
  return nuiCallback('acceptRequest', { fromId });
};

/**
 * Recusa um pedido de relacionamento
 */
export const rejectRequest = (fromId: string): Promise<RequestResponse> => {
  return nuiCallback('rejectRequest', { fromId });
};

/**
 * Termina o relacionamento atual (namoro ou casamento)
 */
export const breakup = (): Promise<RequestResponse> => {
  return nuiCallback('breakup', {});
};

/**
 * Solicita o status atual do relacionamento
 */
export const getRelationshipStatus = (): Promise<RelationshipData> => {
  return nuiCallback('getStatus', {});
};