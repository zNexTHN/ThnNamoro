import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Heart, Send, Sparkles, Users } from 'lucide-react';
import { GlassButton } from './GlassButton';
import { RequestType } from './types';

interface SingleStateProps {
  onSendRequest: (targetId: string, type: RequestType) => void;
}

export function SingleState({ onSendRequest }: SingleStateProps) {
  const [showForm, setShowForm] = useState(false);
  const [targetId, setTargetId] = useState('');
  const [requestType, setRequestType] = useState<RequestType>('dating');

  const handleSubmit = () => {
    if (targetId.trim()) {
      onSendRequest(targetId, requestType);
      setTargetId('');
      setShowForm(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="flex flex-col items-center gap-6 p-6"
    >
      {/* Status Icon */}
      <motion.div
        className="relative"
        animate={{ y: [0, -8, 0] }}
        transition={{ duration: 3, repeat: Infinity, ease: 'easeInOut' }}
      >
        <div className="w-24 h-24 rounded-full romantic-gradient flex items-center justify-center glow-effect">
          <Users className="w-12 h-12 text-foreground" />
        </div>
        <motion.div
          className="absolute -top-2 -right-2"
          animate={{ rotate: [0, 15, -15, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <Sparkles className="w-8 h-8 text-accent" />
        </motion.div>
      </motion.div>

      {/* Status Text */}
      <div className="text-center">
        <h2 className="text-2xl font-bold text-foreground mb-2">Coração Livre</h2>
        <p className="text-muted-foreground">Encontre seu amor no servidor!</p>
      </div>

      <AnimatePresence mode="wait">
        {!showForm ? (
          <motion.div
            key="button"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
          >
            <GlassButton onClick={() => setShowForm(true)} size="lg">
              <Heart className="w-5 h-5" />
              Encontrar um Amor
            </GlassButton>
          </motion.div>
        ) : (
          <motion.div
            key="form"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="w-full max-w-sm space-y-4"
          >
            {/* Target ID Input */}
            <div className="space-y-2">
              <label className="text-sm text-muted-foreground">ID do Jogador</label>
              <input
                type="text"
                value={targetId}
                onChange={(e) => setTargetId(e.target.value)}
                placeholder="Digite o ID..."
                className="w-full px-4 py-3 rounded-xl bg-foreground/10 border border-foreground/20
                         text-foreground placeholder:text-muted-foreground
                         focus:outline-none focus:ring-2 focus:ring-primary/50
                         backdrop-blur-sm transition-all"
              />
            </div>

            {/* Request Type Selector */}
            <div className="space-y-2">
              <label className="text-sm text-muted-foreground">Tipo de Pedido</label>
              <div className="flex gap-2">
                <button
                  onClick={() => setRequestType('dating')}
                  className={`flex-1 px-3 py-3 rounded-xl border transition-all duration-300 text-sm
                    ${requestType === 'dating'
                      ? 'romantic-gradient border-transparent text-foreground'
                      : 'bg-foreground/10 border-foreground/20 text-muted-foreground hover:bg-foreground/15'
                    }`}
                >
                  💕 Namoro
                </button>
                <button
                  onClick={() => setRequestType('engagement')}
                  className={`flex-1 px-3 py-3 rounded-xl border transition-all duration-300 text-sm
                    ${requestType === 'engagement'
                      ? 'romantic-gradient border-transparent text-foreground'
                      : 'bg-foreground/10 border-foreground/20 text-muted-foreground hover:bg-foreground/15'
                    }`}
                >
                  💎 Noivado
                </button>
                <button
                  onClick={() => setRequestType('marriage')}
                  className={`flex-1 px-3 py-3 rounded-xl border transition-all duration-300 text-sm
                    ${requestType === 'marriage'
                      ? 'romantic-gradient border-transparent text-foreground'
                      : 'bg-foreground/10 border-foreground/20 text-muted-foreground hover:bg-foreground/15'
                    }`}
                >
                  💍 Casamento
                </button>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 pt-2">
              <GlassButton
                variant="ghost"
                onClick={() => setShowForm(false)}
                className="flex-1"
              >
                Cancelar
              </GlassButton>
              <GlassButton
                onClick={handleSubmit}
                disabled={!targetId.trim()}
                className="flex-1"
              >
                <Send className="w-4 h-4" />
                Enviar
              </GlassButton>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}