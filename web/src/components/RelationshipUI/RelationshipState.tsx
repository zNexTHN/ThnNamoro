import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Heart, Calendar, AlertTriangle, Award, X, HeartCrack } from 'lucide-react';
import { GlassButton } from './GlassButton';
import { Partner, RelationshipStatus } from './types';

interface RelationshipStateProps {
  status: RelationshipStatus;
  partner: Partner;
  onBreakup: () => void;
}

function getDaysTogether(startDate: Date): number {
  const now = new Date();
  const diffTime = Math.abs(now.getTime() - startDate.getTime());
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

function formatDate(date: Date): string {
  return date.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  });
}

export function RelationshipState({ status, partner, onBreakup }: RelationshipStateProps) {
  const [showConfirm, setShowConfirm] = useState(false);
  const daysTogether = getDaysTogether(partner.startDate);
  const isMarried = status === 'married';
  const isEngaged = status === 'engaged';

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="flex flex-col gap-6 p-6"
    >
      {/* Header */}
      <div className="text-center">
        <motion.div
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full romantic-gradient mb-4"
          animate={{ scale: [1, 1.02, 1] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <Heart className="w-5 h-5 fill-current" />
          <span className="font-semibold">
            {isMarried ? 'Casal Feliz 💍' : isEngaged ? 'Noivos 💎' : 'Namorando 💕'}
          </span>
        </motion.div>
      </div>

      {/* Partner Card */}
      <div className="glass-panel p-6">
        <div className="flex items-center gap-4 mb-4">
          {/* Avatar */}
          <motion.div
            className="w-16 h-16 rounded-full romantic-gradient flex items-center justify-center text-2xl font-bold overflow-hidden"
            whileHover={{ scale: 1.05 }}
          >
            {partner.avatar ? (
              <img src={partner.avatar} alt={partner.name} className="w-full h-full object-cover" />
            ) : (
              partner.name.charAt(0).toUpperCase()
            )}
          </motion.div>

          {/* Partner Info */}
          <div className="flex-1">
            <h3 className="text-xl font-bold text-foreground">{partner.name}</h3>
            <p className="text-muted-foreground text-sm">ID: {partner.id}</p>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-foreground/10 rounded-xl p-3 text-center">
            <Calendar className="w-5 h-5 mx-auto mb-1 text-primary" />
            <p className="text-xs text-muted-foreground">Início</p>
            <p className="text-sm font-semibold text-foreground">{formatDate(partner.startDate)}</p>
          </div>
          <div className="bg-foreground/10 rounded-xl p-3 text-center">
            <Heart className="w-5 h-5 mx-auto mb-1 text-accent fill-accent" />
            <p className="text-xs text-muted-foreground">Dias Juntos</p>
            <p className="text-sm font-semibold text-foreground">{daysTogether} dias</p>
          </div>
        </div>
      </div>

      {/* Marriage/Engagement Certificate */}
      <AnimatePresence>
        {(isMarried || isEngaged) && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="relative"
          >
            <div className="glass-panel p-6 border-2 border-primary/30 overflow-hidden">
              {/* Shimmer effect */}
              <div className="absolute inset-0 shimmer pointer-events-none" />
              
              {/* Certificate content */}
              <div className="relative text-center">
                <Award className="w-10 h-10 mx-auto mb-3 text-primary" />
                <h3 className="text-2xl font-romantic romantic-gradient-text mb-2">
                  {isMarried ? 'Certidão de Casamento' : 'Certidão de Noivado'}
                </h3>
                <p className="text-muted-foreground text-sm mb-4">
                  Este documento certifica a união entre
                </p>
                <div className="flex items-center justify-center gap-3 mb-4">
                  <span className="text-foreground font-semibold">Você</span>
                  <Heart className="w-5 h-5 text-primary fill-primary" />
                  <span className="text-foreground font-semibold">{partner.name}</span>
                </div>
                <p className="text-xs text-muted-foreground">
                  {isMarried ? 'Casados' : 'Noivos'} desde {formatDate(partner.startDate)}
                </p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Danger Zone */}
      <div className="mt-auto">
        <AnimatePresence mode="wait">
          {!showConfirm ? (
            <motion.button
              key="danger-btn"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setShowConfirm(true)}
              className="w-full py-3 rounded-xl text-sm text-muted-foreground hover:text-destructive
                       border border-transparent hover:border-destructive/30 transition-all duration-300
                       flex items-center justify-center gap-2"
            >
              <AlertTriangle className="w-4 h-4" />
              {isMarried ? 'Pedir Divórcio' : isEngaged ? 'Romper Noivado' : 'Terminar Relacionamento'}
            </motion.button>
          ) : (
            <motion.div
              key="confirm"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="glass-panel p-4 border-destructive/30"
            >
              <p className="text-center text-foreground mb-4 text-sm">
                {isMarried
                  ? 'Tem certeza que deseja se divorciar?'
                  : isEngaged
                  ? 'Tem certeza que deseja romper o noivado?'
                  : 'Tem certeza que deseja terminar?'}
              </p>
              <div className="flex gap-3">
                <GlassButton
                  variant="ghost"
                  onClick={() => setShowConfirm(false)}
                  className="flex-1"
                  size="sm"
                >
                  <X className="w-4 h-4" />
                  Cancelar
                </GlassButton>
                <GlassButton
                  variant="danger"
                  onClick={onBreakup}
                  className="flex-1"
                  size="sm"
                >
                  <HeartCrack className="w-4 h-4" />
                  Confirmar
                </GlassButton>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
}