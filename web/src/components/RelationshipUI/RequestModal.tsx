import { motion } from 'framer-motion';
import { Heart, HeartCrack, Sparkles } from 'lucide-react';
import { GlassButton } from './GlassButton';
import { PendingRequest } from './types';
import confetti from 'canvas-confetti';

interface RequestModalProps {
  request: PendingRequest;
  onAccept: () => void;
  onReject: () => void;
}

const fireConfetti = () => {
  const count = 200;
  const defaults = {
    origin: { y: 0.7 },
    zIndex: 9999,
  };

  function fire(particleRatio: number, opts: confetti.Options) {
    confetti({
      ...defaults,
      ...opts,
      particleCount: Math.floor(count * particleRatio),
    });
  }

  fire(0.25, {
    spread: 26,
    startVelocity: 55,
    colors: ['#ff6b9d', '#c44eff', '#ff4e91'],
  });

  fire(0.2, {
    spread: 60,
    colors: ['#ff6b9d', '#c44eff', '#ff4e91'],
  });

  fire(0.35, {
    spread: 100,
    decay: 0.91,
    scalar: 0.8,
    colors: ['#ff6b9d', '#c44eff', '#ffd700'],
  });

  fire(0.1, {
    spread: 120,
    startVelocity: 25,
    decay: 0.92,
    scalar: 1.2,
    colors: ['#ff6b9d', '#c44eff', '#ff4e91'],
  });

  fire(0.1, {
    spread: 120,
    startVelocity: 45,
    colors: ['#ffd700', '#ff6b9d', '#c44eff'],
  });
};

export function RequestModal({ request, onAccept, onReject }: RequestModalProps) {
  const handleAccept = () => {
    fireConfetti();
    setTimeout(onAccept, 500);
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 flex items-center justify-center z-50 p-4"
    >
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="absolute inset-0 bg-black/60" 
        onClick={onReject}
      />

      {/* Modal */}
      <motion.div
        initial={{ scale: 0.8, opacity: 0, y: 20 }}
        animate={{ scale: 1, opacity: 1, y: 0 }}
        exit={{ scale: 0.8, opacity: 0, y: 20 }}
        transition={{ type: 'spring', damping: 20 }}
        className="glass-panel p-8 max-w-md w-full relative z-10"
      >
        {/* Floating sparkles */}
        <motion.div
          className="absolute -top-6 left-1/2 -translate-x-1/2"
          animate={{ y: [0, -5, 0], rotate: [0, 10, -10, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <Sparkles className="w-12 h-12 text-accent" />
        </motion.div>

        {/* Heartbeat Icon */}
        <div className="flex justify-center mb-6">
          <motion.div
            className="w-20 h-20 rounded-full romantic-gradient flex items-center justify-center"
            animate={{
              scale: [1, 1.15, 1, 1.15, 1],
            }}
            transition={{
              duration: 1.2,
              repeat: Infinity,
              ease: 'easeInOut',
            }}
          >
            <Heart className="w-10 h-10 text-foreground fill-foreground" />
          </motion.div>
        </div>

        {/* Title */}
        <div className="text-center mb-6">
          <h2 className="text-3xl font-romantic text-foreground mb-2">
            {request.type === 'marriage' ? 'Pedido de Casamento!' : 'Pedido de Namoro!'}
          </h2>
          <p className="text-muted-foreground">
            <span className="text-primary font-semibold">{request.fromName}</span>
            {request.type === 'marriage'
              ? ' quer se casar com você!'
              : ' quer namorar com você!'}
          </p>
        </div>

        {/* Request Type Badge */}
        <div className="flex justify-center mb-8">
          <span className="px-4 py-2 rounded-full romantic-gradient text-foreground text-sm font-semibold">
            {request.type === 'marriage' ? '💍 Casamento' : '💕 Namoro'}
          </span>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-4">
          <GlassButton
            variant="danger"
            onClick={onReject}
            size="lg"
            className="flex-1"
          >
            <HeartCrack className="w-5 h-5" />
            Recusar
          </GlassButton>
          <GlassButton
            variant="success"
            onClick={handleAccept}
            size="lg"
            className="flex-1"
          >
            <Heart className="w-5 h-5 fill-current" />
            Aceitar
          </GlassButton>
        </div>
      </motion.div>
    </motion.div>
  );
}
