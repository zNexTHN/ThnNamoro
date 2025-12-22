import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Heart, Loader2 } from 'lucide-react';
import { SingleState } from './SingleState';
import { RequestModal } from './RequestModal';
import { RelationshipState } from './RelationshipState';
import { RelationshipState as IRelationshipState, RequestType, PendingRequest } from './types';
import { useFiveM } from '@/hooks/useFiveM';
import { isInFiveM } from '@/utils/fivem';

interface RelationshipUIProps {
  onClose?: () => void;
}

export function RelationshipUI({ onClose }: RelationshipUIProps) {
  const {
    isOpen,
    isLoading,
    relationshipData,
    pendingRequest: fivemPendingRequest,
    sendRequest: fivemSendRequest,
    acceptRequest: fivemAcceptRequest,
    rejectRequest: fivemRejectRequest,
    breakup: fivemBreakup,
    close: fivemClose,
  } = useFiveM();

  // Estado local para desenvolvimento (quando não está no FiveM)
  const [devState, setDevState] = useState<IRelationshipState>({
    status: 'single',
  });
  const [devShowRequestModal, setDevShowRequestModal] = useState(false);

  // Usa dados do FiveM se disponível, senão usa estado de dev
  const inFiveM = isInFiveM();
  
  const state: IRelationshipState = inFiveM && relationshipData 
    ? {
        status: relationshipData.status,
        partner: relationshipData.partner ? {
          id: relationshipData.partner.id,
          name: relationshipData.partner.name,
          avatar: relationshipData.partner.avatar,
          startDate: new Date(relationshipData.partner.startDate),
        } : undefined,
        pendingRequest: fivemPendingRequest ? {
          fromId: fivemPendingRequest.fromId,
          fromName: fivemPendingRequest.fromName,
          type: fivemPendingRequest.type,
        } : undefined,
      }
    : devState;

  const showRequestModal = inFiveM ? !!fivemPendingRequest : devShowRequestModal;

  // Handlers
  const handleSendRequest = async (targetId: string, type: RequestType) => {
    if (inFiveM) {
      await fivemSendRequest({ targetId, type });
    } else {
      // Simulação para desenvolvimento
      console.log(`[DEV] Enviando pedido de ${type} para jogador ${targetId}`);
      setTimeout(() => {
        setDevState({
          status: 'pending',
          pendingRequest: {
            fromId: targetId,
            fromName: `Player ${targetId}`,
            type,
          },
        });
        setDevShowRequestModal(true);
      }, 500);
    }
  };

  const handleAcceptRequest = async () => {
    if (inFiveM) {
      await fivemAcceptRequest();
    } else {
      // Simulação para desenvolvimento
      if (devState.pendingRequest) {
        setDevState({
          status: devState.pendingRequest.type === 'marriage' ? 'married' : 'dating',
          partner: {
            id: devState.pendingRequest.fromId,
            name: devState.pendingRequest.fromName,
            startDate: new Date(),
          },
        });
      }
      setDevShowRequestModal(false);
    }
  };

  const handleRejectRequest = async () => {
    if (inFiveM) {
      await fivemRejectRequest();
    } else {
      setDevState({ status: 'single' });
      setDevShowRequestModal(false);
    }
  };

  const handleBreakup = async () => {
    if (inFiveM) {
      await fivemBreakup();
    } else {
      setDevState({ status: 'single' });
    }
  };

  const handleClose = () => {
    if (inFiveM) {
      fivemClose();
    }
    onClose?.();
  };

  // Não renderiza se não está aberto (apenas em FiveM)
  if (inFiveM && !isOpen) {
    return null;
  }

  return (
    <div className="fixed inset-0 flex items-center justify-center p-4">
      {/* Main Container */}
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.9, y: 20 }}
        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        className="glass-panel w-full max-w-md min-h-[500px] flex flex-col relative overflow-hidden"
      >
        {/* Background glow effect */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-64 h-64 bg-primary/20 rounded-full blur-3xl" />
          <div className="absolute bottom-0 right-0 w-48 h-48 bg-secondary/20 rounded-full blur-3xl" />
        </div>

        {/* Header */}
        <div className="relative z-10 flex items-center justify-between p-6 border-b border-foreground/10">
          <div className="flex items-center gap-3">
            <motion.div
              animate={{ rotate: [0, 10, -10, 0] }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              <Heart className="w-6 h-6 text-primary fill-primary" />
            </motion.div>
            <h1 className="text-xl font-bold text-foreground">Relacionamento</h1>
          </div>
          
          <div className="flex items-center gap-2">
            {isLoading && (
              <Loader2 className="w-5 h-5 text-muted-foreground animate-spin" />
            )}
            <motion.button
              whileHover={{ scale: 1.1, rotate: 90 }}
              whileTap={{ scale: 0.9 }}
              onClick={handleClose}
              className="w-8 h-8 rounded-full bg-foreground/10 flex items-center justify-center
                       text-muted-foreground hover:text-foreground hover:bg-foreground/20
                       transition-colors"
            >
              <X className="w-5 h-5" />
            </motion.button>
          </div>
        </div>

        {/* Content */}
        <div className="relative z-10 flex-1 overflow-y-auto">
          <AnimatePresence mode="wait">
            {(state.status === 'single' || state.status === 'pending') && !state.partner && (
              <SingleState key="single" onSendRequest={handleSendRequest} />
            )}

            {(state.status === 'dating' || state.status === 'engaged' || state.status === 'married') && state.partner && (
              <RelationshipState
                key="relationship"
                status={state.status}
                partner={state.partner}
                onBreakup={handleBreakup}
              />
            )}
          </AnimatePresence>
        </div>
      </motion.div>

      {/* Request Modal */}
      <AnimatePresence>
        {showRequestModal && state.pendingRequest && (
          <RequestModal
            request={state.pendingRequest}
            onAccept={handleAcceptRequest}
            onReject={handleRejectRequest}
          />
        )}
      </AnimatePresence>
    </div>
  );
}